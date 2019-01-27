defmodule Deli.Release do
  import Deli.Shell
  alias Deli.Config
  alias Deli.Templates.{Compose, Dockerfile, EdeliverConfig}

  @moduledoc false

  def build(tag, target) do
    target_mix_env = target |> Config.mix_env()

    ensure_edeliver_config()
    clear_previous_releases()
    boot_docker()
    clear_remote_releases()

    edeliver(:build, [:release, "--tag", tag, "--mix-env", target_mix_env])
  end

  defp boot_docker do
    docker_port = Config.docker_port()
    ensure_dockerfile()
    ensure_docker_compose()
    ensure_docker_authorized_keys()
    docker_compose(:down, ["--remove-orphans"], [0, 1])
    docker_compose(:build, [:edeliver])
    docker_compose(:up, ["-d", :edeliver])
    :timer.sleep(1_000)
    cmd("ssh-keygen", ["-R", "\[0.0.0.0\]:#{docker_port}"])
    {:ok, scan} = "ssh-keyscan" |> cmd_result(["-p", docker_port, "0.0.0.0"])
    write_file("~/.ssh/known_hosts", "\n#{scan}\n", [:append])
  end

  defp ensure_edeliver_config do
    path = ".deliver/config"

    unless path |> file_exists? do
      content =
        EdeliverConfig.build(
          Config.app(),
          Config.hosts(:staging),
          Config.hosts(:prod),
          Config.docker_port()
        )

      write_file(path, content)
      add_to_gitignore(path)
      add_to_gitignore(".deliver/releases")
    end
  end

  defp ensure_dockerfile do
    path = ".deliver/Dockerfile"

    unless path |> file_exists? do
      content =
        Dockerfile.build(
          Config.docker_build_target(),
          Config.app()
        )

      write_file(path, content)
      add_to_gitignore(path)
      add_to_gitignore(".deliver/releases")
    end
  end

  defp ensure_docker_compose do
    path = ".deliver-docker-compose.yml"

    unless path |> file_exists? do
      content =
        Compose.build(
          Config.app(),
          Config.docker_port()
        )

      write_file(path, content)
      add_to_gitignore(path)
    end
  end

  defp ensure_docker_authorized_keys do
    app = Config.app()
    path = ".deliver/authorized_keys/#{app}_id_rsa"

    keygen_args = [
      "-f",
      ".deliver/authorized_keys/#{app}_id_rsa",
      "-t",
      :rsa,
      "-b",
      4096
    ]

    unless path |> file_exists? do
      cmd(:mkdir, ["-p", ".deliver/authorized_keys"])
      cmd("ssh-keygen", keygen_args)
      add_to_gitignore("/.deliver/authorized_keys/*")
    end

    cmd(:chmod, [400, path])
  end

  defp add_to_gitignore(path) do
    gitignore = ".gitignore"
    content = gitignore |> expand_path |> File.read!()

    unless content |> String.contains?(path) do
      write_file(gitignore, "#{path}\n", [:append])
    end
  end

  defp clear_previous_releases do
    cmd(:rm, ["-rf", ".deliver/releases"], [0, 1])
  end

  defp clear_remote_releases do
    cmd = [:edeliver, :bash, "-c", "\"rm -rf /usr/local/builds/*\""]
    docker_compose(:exec, cmd, [0, 127])
  end
end
