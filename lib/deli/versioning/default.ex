defmodule Deli.Versioning.Default do
  import Deli.Shell
  alias Deli.Config

  @moduledoc "Provides version git tag enforcing"

  @behaviour Deli.Versioning

  @impl true
  def version_tag(nil) do
    version = Config.version()
    tag = git_tags() |> List.last()
    if tag, do: version |> compare(tag), else: version |> create
  end

  def version_tag("v" <> version), do: version |> version_tag

  def version_tag(version) when is_binary(version) do
    sanitized_version = version |> Version.parse!() |> to_string
    {:ok, "v#{sanitized_version}"}
  end

  defp compare(version, tag) do
    case version |> Version.compare(tag) do
      :lt ->
        error!("Remove tag #{tag}, or adapt Mixfile version")

      :gt ->
        version |> create

      :eq ->
        current_sha = "HEAD" |> git_sha
        tag_sha = "v#{tag}" |> git_sha

        if current_sha == tag_sha do
          {:ok, "v#{tag}"}
        else
          error!("""
            Mix version equals latest tag, but they have different revisions.
            Bump version in `mix.exs` before continue.
          """)
        end
    end
  end

  defp create(version) do
    tag = "v#{version}"
    cmd(:git, [:tag, tag])
    cmd(:git, [:push, :origin, tag])
    {:ok, tag}
  end

  defp git_sha(sha_selector) do
    {:ok, content} = :git |> cmd_result(["rev-list", "-n", 1, sha_selector])
    content
  end

  defp git_tags do
    cmd(:git, [:fetch, "--tags"])

    {:ok, content} = :git |> cmd_result([:tag, "-l", "--sort", "version:refname"], [0])

    content
    |> String.split("\n")
    |> Enum.filter(&(&1 != ""))
    |> Enum.map(fn "v" <> n -> n |> Version.parse!() end)
  end
end
