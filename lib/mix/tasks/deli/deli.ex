defmodule Mix.Tasks.Deli do
  use Mix.Task
  alias Deli.Config
  alias Deli.Templates.{EdeliverCompose, EdeliverConfig}

  # TODO gen keys
  # TODO gen dockerfile, ignoring it, based on a :target_os

  @moduledoc """
  To deploy current master into staging, do:

      $ mix deli

  Or, if you want to specify a version or target environment, do:

      $ mix deli --version=1.0.0 --target=production

  It will ask for confirmation after release is built, before deploy.
  If you don't want that extra step, pass `-y` when calling this task.
  """

  @shortdoc "Deploys application"

  def run(args) do
    Application.ensure_all_started(:deli)
    options = args |> parse_options

    if assets?(options), do: System.put_env("ASSETS", "1")

    tag = options |> fetch_version_tag
    target = options |> Keyword.get(:target, "staging")
    target_mix_env = target |> Config.mix_env()

    ensure_edeliver_config()
    ensure_edeliver_dockerfile()
    clear_previous_releases()
    boot_docker()
    clear_remote_releases()

    edeliver("build release --tag=#{tag} --mix-env=#{target_mix_env}")

    if confirm_deploy?(tag, target, options) do
      IO.puts("🤞")
      edeliver("deploy release to #{target}")
      restart_target(target)
    else
      IO.puts([IO.ANSI.green(), "Deploy aborted by user", IO.ANSI.reset()])
    end
  end

  defp confirm_deploy?(tag, target, options) do
    message = "Deploy #{tag} to #{target}?"

    if options |> Keyword.get(:yes) do
      IO.puts("#{message} (Y/n) YES")
      true
    else
      message |> Mix.shell().yes?()
    end
  end

  defp fetch_version_tag(options) when is_list(options) do
    options
    |> Keyword.get(:version)
    |> fetch_version_tag
  end

  defp fetch_version_tag(nil) do
    version = Mix.Project.get().project[:version] |> Version.parse!()
    tag = git_tags() |> List.last()
    action = if tag, do: {:compare, version, tag}, else: {:create, version}
    action |> fetch_version_tag
  end

  defp fetch_version_tag("v" <> version), do: version |> fetch_version_tag

  defp fetch_version_tag(version) when is_binary(version) do
    sanitized_version = version |> Version.parse!() |> to_string
    "v#{sanitized_version}"
  end

  defp fetch_version_tag({:compare, version, tag}) do
    case version |> Version.compare(tag) do
      :lt ->
        error!("Remove tag #{tag}, or adapt Mixfile version")

      :gt ->
        {:create, version} |> fetch_version_tag

      :eq ->
        current_sha = "HEAD" |> git_sha
        tag_sha = "v#{tag}" |> git_sha

        if current_sha == tag_sha do
          "v#{tag}"
        else
          error!("""
            Mix version equals latest tag, but they have different revisions.
            Bump version in `mix.exs` before continue.
          """)
        end
    end
  end

  defp fetch_version_tag({:create, version}) do
    version |> create_version_tag
  end

  defp create_version_tag(version) do
    tag = "v#{version}"
    cmd("git tag #{tag}")
    cmd("git push origin #{tag}")
    tag
  end

  defp git_sha(sha_selector) do
    "git rev-list -n 1 #{sha_selector}" |> cmd_result
  end

  defp git_tags do
    cmd("git fetch --tags")

    "git tag -l --sort version:refname"
    |> cmd_result
    |> String.split("\n")
    |> Enum.filter(&(&1 != ""))
    |> Enum.map(fn "v" <> n -> n |> Version.parse!() end)
  end

  defp edeliver(command) do
    cmd("mix edeliver #{command} --verbose")
  end

  defp restart_target(target) do
    target |> Config.hosts() |> Enum.each(&restart_target(target, &1))
  end

  defp restart_target(target, host) do
    app = Config.app()

    IO.puts("Restarting target...")
    cmd("ssh #{app}@#{host} 'sudo systemctl restart #{app}'")
    IO.puts("Restarted target")

    :timer.sleep(1_000)

    if service_active?(host), do: edeliver("ping #{target}")
  end

  defp service_active?(host) do
    app = Config.app()
    status = "ssh #{app}@#{host} 'systemctl status #{app}'" |> cmd_result

    if status =~ ~r/Active\: active \(running\)/ do
      IO.puts([IO.ANSI.green(), "#{app} running", IO.ANSI.reset()])
      true
    else
      IO.puts([IO.ANSI.red(), "#{app} not running", IO.ANSI.reset()])
      IO.puts(status)
      false
    end
  end

  defp boot_docker do
    docker_port = Config.docker_port()
    ensure_docker_compose()
    ensure_docker_authorized_keys()
    docker_compose("down")
    docker_compose("build edeliver")
    docker_compose("up -d edeliver")
    :timer.sleep(1_000)
    cmd("ssh-keygen -R \[0.0.0.0\]:#{docker_port}")
    cmd("ssh-keyscan -p #{docker_port} 0.0.0.0 >> ~/.ssh/known_hosts")
  end

  defp ensure_edeliver_config do
    path = ".deliver/config"

    unless path |> File.exists?() do
      content =
        EdeliverConfig.build(
          Config.app(),
          Config.hosts(:staging),
          Config.hosts(:prod),
          Config.docker_port()
        )

      File.write!(path, content)
      add_to_gitignore(path)
      add_to_gitignore(".deliver/releases")
    end
  end

  defp ensure_edeliver_dockerfile do
    path = ".deliver/Dockerfile"

    unless path |> File.exists?() do
      content =
        EdeliverDockerfile.build(
          Config.app(),
          Config.docker_build_target()
        )

      File.write!(path, content)
      add_to_gitignore(path)
      add_to_gitignore(".deliver/releases")
    end
  end

  defp ensure_docker_compose do
    path = ".deliver/docker-compose.yml"

    unless path |> File.exists?() do
      content =
        EdeliverCompose.build(
          Config.app(),
          Config.docker_port()
        )

      File.write!(path, content)
      add_to_gitignore(path)
    end
  end

  defp ensure_docker_authorized_keys do
    app = Config.app()
    path = ".deliver/authorized_keys/#{app}_id_rsa"

    unless path |> File.exists?() do
      # TODO generate key
      IO.puts("TODO generate key1")
      add_to_gitignore("/.deliver/authorized_keys/*")
    end

    cmd("chmod 400 #{path}")
  end

  defp add_to_gitignore(path) do
    gitignore = ".gitignore"
    content = gitignore |> File.read!()

    unless content |> String.contains?(path) do
      File.write!(gitignore, path, [:append])
    end
  end

  defp clear_previous_releases do
    cmd("rm -rf .deliver/releases")
  end

  defp clear_remote_releases do
    docker_compose("exec edeliver bash -c \"rm -rf /usr/local/builds/*\"")
  end

  defp docker_compose(command) do
    no_tty = "COMPOSE_INTERACTIVE_NO_CLI=1"
    cmd("#{no_tty} docker-compose #{command}")
  end

  defp cmd(command) do
    with 0 <- Mix.shell().cmd(command) do
      :ok
    else
      signal ->
        IO.puts([
          IO.ANSI.reset(),
          IO.ANSI.red_background(),
          IO.ANSI.white(),
          "Deploy command failed: `#{command}`",
          IO.ANSI.reset()
        ])

        exit({:shutdown, signal})
    end
  end

  defp cmd_result(command) do
    command
    |> to_charlist
    |> :os.cmd()
    |> to_string
    |> String.trim()
  end

  @spec error!(String.t()) :: no_return
  defp error!(message) do
    Mix.shell().error(message)
    exit({:shutdown, 1})
  end

  defp assets?(options) do
    if options |> Keyword.get(:assets) do
      true
    else
      :deli |> Application.get_env(:assets, false)
    end
  end

  defp parse_options(args) do
    options = [version: :string, target: :string, assets: :boolean, yes: :boolean]
    aliases = [v: :version, t: :target, a: :assets, y: :yes]

    args
    |> OptionParser.parse(aliases: aliases, switches: options)
    |> elem(0)
  end
end
