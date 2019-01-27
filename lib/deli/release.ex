defmodule Deli.Release do
  import Deli.Shell
  alias Deli.Config
  alias Deli.Templates.{Compose, Dockerfile, EdeliverConfig}

  @moduledoc "Provisions a local docker and builds release"

  def build(tag, target) do
    target_mix_env = target |> Config.mix_env()

    ensure_edeliver_config()
    ensure_edeliver_dockerfile()
    clear_previous_releases()
    boot_docker()
    clear_remote_releases()

    edeliver("build release --tag=#{tag} --mix-env=#{target_mix_env}")
  end

  defp boot_docker do
    docker_port = Config.docker_port()
    ensure_docker_compose()
    ensure_docker_authorized_keys()
    docker_compose("down --remove-orphans")
    docker_compose("build edeliver")
    docker_compose("up -d edeliver")
    :timer.sleep(1_000)
    cmd("ssh-keygen -R \[0.0.0.0\]:#{docker_port}")
    cmd("ssh-keyscan -p #{docker_port} 0.0.0.0 >> ~/.ssh/known_hosts")
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

  defp ensure_edeliver_dockerfile do
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

    unless path |> file_exists? do
      IO.puts("You need to generate ssh key in #{path}")
      add_to_gitignore("/.deliver/authorized_keys/*")
    end

    cmd("chmod 400 #{path}")
  end

  defp add_to_gitignore(path) do
    gitignore = ".gitignore"
    content = gitignore |> expand_path |> File.read!()

    unless content |> String.contains?(path) do
      write_file(gitignore, "#{path}\n", [:append])
    end
  end

  defp clear_previous_releases do
    cmd("rm -rf .deliver/releases")
  end

  defp clear_remote_releases do
    docker_compose("exec edeliver bash -c \"rm -rf /usr/local/builds/*\"")
  end
end
