defmodule Deli.Release.Remote do
  import Deli.Shell
  alias Deli.{Config, Versioning}
  alias Deli.Templates.EdeliverConfig

  @moduledoc "Release strategy that relies on a remote build host"

  @behaviour Deli.Release

  @impl true
  def build(tag, target) do
    ensure_edeliver_config()
    clear_previous_releases()
    edeliver_build(tag, target)
  end

  @spec edeliver_build(Versioning.tag(), Deli.env()) :: :ok
  def edeliver_build(tag, target) do
    target_mix_env = Config.mix_env(target)
    edeliver(:build, [:release, "--tag=#{tag}", "--mix-env=#{target_mix_env}"])
  end

  @spec ensure_edeliver_config(boolean) :: :ok
  def ensure_edeliver_config(remote? \\ true) do
    path = ".deliver/config"

    unless file_exists?(path) do
      host_provider = Config.host_provider()
      hosts = fn env -> host_provider.hosts(env) end
      staging_hosts = hosts.(:staging)
      prod_hosts = hosts.(:prod)

      content =
        EdeliverConfig.build(
          Config.app(),
          staging_hosts,
          prod_hosts,
          Config.app_user(:staging),
          Config.app_user(:prod),
          Config.docker_build_user(),
          Config.docker_build_port(),
          remote?,
          Config.remote_build_host(),
          Config.remote_build_user()
        )

      dir = Path.dirname(path)
      :ok = file_handler().mkdir_p(dir)
      write_file(path, content)
      add_to_gitignore(path)
      add_to_gitignore(".deli/releases")
    end
  end

  @spec clear_previous_releases() :: :ok
  def clear_previous_releases do
    cmd(:rm, ["-rf", ".deli/releases"], [0, 1])
  end

  @spec add_to_gitignore(Path.t()) :: :ok
  def add_to_gitignore(path) do
    gitignore = ".gitignore"
    content = gitignore |> expand_path |> file_handler().read!()

    unless String.contains?(content, path) do
      write_file(gitignore, "#{path}\n", [:append])
    end
  end

  defp file_handler, do: Config.__file_handler__()
end
