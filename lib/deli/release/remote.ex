defmodule Deli.Release.Remote do
  import Deli.Shell
  alias Deli.{Config, Versioning}

  @moduledoc "Release strategy that relies on a remote build host"

  @behaviour Deli.Release

  @impl true
  def build(tag, target) do
    ensure_release_config()
    clear_previous_releases()

    remote_build(
      tag,
      target,
      Config.remote_build_user(),
      Config.remote_build_host()
    )
  end

  @spec remote_build(
          Versioning.tag(),
          Deli.env(),
          user :: atom,
          host :: Deli.host()
        ) :: :ok
  def remote_build(tag, target, user, host) do
    app = Config.app()
    build_path = Config.build_path()
    id = "#{user}@#{host}"
    target_mix_env = Config.mix_env(target)
    release = "#{app}-#{target_mix_env}-#{tag}"
    path = "#{release}.tar.gz"
    p = &Path.join(build_path, &1)

    git_archive_args = [
      :archive,
      "--format=tar.gz",
      "-o",
      path,
      tag
    ]

    cmd(:git, git_archive_args)
    cmd(:ssh, [id, "rm -rf #{p.("*")}"])
    cmd(:ssh, [id, "mkdir -p #{p.(release)}"])
    cmd(:scp, [path, "#{id}:\"#{build_path}\""])
    cmd(:ssh, [id, "tar --directory=\"#{p.(release)}\" -xvzf #{p.(path)}"])
    cmd(:ssh, ["-t", id, "cd #{p.(release)}; MIX_ENV=#{target_mix_env} mix release"])

    local_releases_path = ".deli/releases/#{release}"
    cmd(:mkdir, ["-p", local_releases_path])
    app_release_path = p.("_build/#{target_mix_env}/rel/#{app}")
    cmd(:scp, ["-r", "#{id}:\"#{app_release_path}\"", local_releases_path])
  end

  @spec ensure_release_config(boolean) :: :ok
  def ensure_release_config(_remote? \\ true) do
    add_to_gitignore(".deli/releases")
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
