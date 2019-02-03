defmodule Deli.Release.Remote do
  import Deli.Shell
  alias Deli.Config
  alias Deli.Templates.EdeliverConfig

  @moduledoc false

  @behaviour Deli.Release

  @impl true
  def build(tag, target) do
    ensure_edeliver_config()
    clear_previous_releases()
    edeliver_build(tag, target)
  end

  def edeliver_build(tag, target) do
    target_mix_env = target |> Config.mix_env()
    edeliver(:build, [:release, "--tag=#{tag}", "--mix-env=#{target_mix_env}"])
  end

  def ensure_edeliver_config(remote? \\ true) do
    path = ".deli/edeliver_config"

    unless path |> file_exists? do
      host_provider = Config.host_provider()
      hosts = fn env -> env |> host_provider.hosts() end
      staging_hosts = hosts.(:staging)
      prod_hosts = hosts.(:prod)

      content =
        EdeliverConfig.build(
          Config.app(),
          staging_hosts,
          prod_hosts,
          Config.app_user(:staging),
          Config.app_user(:prod),
          Config.docker_build_port(),
          remote?
        )

      dir = path |> Path.dirname()
      :ok = File.mkdir_p(dir)
      write_file(path, content)
      add_to_gitignore(path)
      add_to_gitignore(".deli/releases")
    end
  end

  def clear_previous_releases do
    cmd(:rm, ["-rf", ".deli/releases"], [0, 1])
  end

  def add_to_gitignore(path) do
    gitignore = ".gitignore"
    content = gitignore |> expand_path |> File.read!()

    unless content |> String.contains?(path) do
      write_file(gitignore, "#{path}\n", [:append])
    end
  end
end
