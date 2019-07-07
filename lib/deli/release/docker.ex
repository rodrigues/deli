defmodule Deli.Release.Docker do
  import Deli.Shell

  import Deli.Release.Remote,
    only: [
      add_to_gitignore: 1,
      clear_previous_releases: 0,
      remote_build: 4,
      ensure_release_config: 1
    ]

  alias Deli.Config
  alias Deli.Templates.{Compose, Dockerfile}

  @moduledoc "Release strategy that creates a local docker to build"

  @behaviour Deli.Release

  @type tag :: atom | String.t() | pos_integer
  @type docker_image :: atom | String.t()
  @type deli_image :: :centos | :debian
  @type beam_versions :: Keyword.t()

  @type build_target ::
          docker_image
          | {docker_image, tag}
          | {:deli, deli_image}
          | {:deli, {deli_image, tag}}
          | {:deli, deli_image, beam_versions}
          | {:deli, {deli_image, tag}, beam_versions}

  @impl true
  def build(tag, target) do
    ensure_release_config(false)
    clear_previous_releases()
    boot_docker()
    clear_remote_releases()

    remote_build(
      tag,
      target,
      Config.docker_build_user(),
      Config.docker_build_host()
    )
  end

  defp boot_docker do
    port = Config.docker_build_port()
    ensure_dockerfile()
    ensure_docker_compose()
    ensure_docker_authorized_keys()
    docker_compose(:down, ["--remove-orphans"], [0, 1])
    docker_compose(:build, [:deli])
    docker_compose(:up, ["-d", :deli])
    :timer.sleep(1_000)
    cmd("ssh-keygen", ["-R", "\[0.0.0.0\]:#{port}"])
    {:ok, scan} = cmd_result("ssh-keyscan", ["-p", port, "0.0.0.0"])
    write_file("~/.ssh/known_hosts", "\n#{scan}\n", [:append])
  end

  defp ensure_dockerfile do
    path = ".deli/Dockerfile"

    unless file_exists?(path) do
      content =
        Dockerfile.build(
          Config.docker_build_image(),
          Config.app(),
          Config.docker_build_user(),
          Config.docker_build_yarn?(),
          Config.docker_build_node_version()
        )

      write_file(path, content)
      add_to_gitignore(path)
      add_to_gitignore(".deli/releases")
    end
  end

  defp ensure_docker_compose do
    path = ".deli/docker-compose.yml"

    unless file_exists?(path) do
      content =
        Compose.build(
          Config.app(),
          Config.docker_build_port()
        )

      write_file(path, content)
      add_to_gitignore(path)
    end
  end

  defp ensure_docker_authorized_keys do
    app = Config.app()
    path = ".deli/authorized_keys/#{app}_id_rsa"

    keygen_args = [
      "-f",
      ".deli/authorized_keys/#{app}_id_rsa",
      "-t",
      :rsa,
      "-b",
      4096
    ]

    unless file_exists?(path) do
      cmd(:mkdir, ["-p", ".deli/authorized_keys"])
      cmd("ssh-keygen", keygen_args)
      error!("Commit authorized keys before proceeding")
    end

    cmd(:chmod, [400, path])
  end

  defp clear_remote_releases do
    build_path = Config.build_path()
    rm_path = Path.join(build_path, "*")
    cmd = [:deli, :bash, "-c", "\"rm -rf #{rm_path}\""]
    docker_compose(:exec, cmd, [0, 127])
  end
end
