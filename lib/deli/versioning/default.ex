defmodule Deli.Versioning.Default do
  import Deli.Shell
  alias Deli.Config

  @moduledoc "Provides version git tag enforcing"

  @behaviour Deli.Versioning

  @impl true
  def version_tag(nil) do
    version = Config.version()
    tag = List.last(git_tags())
    if tag, do: compare(version, tag), else: create(version)
  end

  def version_tag("v" <> version), do: version_tag(version)

  def version_tag(version) when is_binary(version) do
    sanitized_version = version |> Version.parse!() |> to_string
    {:ok, "v#{sanitized_version}"}
  end

  defp compare(version, tag) do
    case Version.compare(version, tag) do
      :lt ->
        error!("Remove tag #{tag}, or adapt Mixfile version")

      :gt ->
        create(version)

      :eq ->
        current_sha = git_sha("HEAD")
        tag_sha = git_sha("v#{tag}")

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
    {:ok, content} = cmd_result(:git, ["rev-list", "-n", 1, sha_selector])
    content
  end

  defp git_tags do
    cmd(:git, [:fetch, "--tags"])

    {:ok, content} = cmd_result(:git, [:tag, "-l", "--sort", "version:refname"], [0])

    content
    |> String.split("\n")
    |> Enum.filter(&(&1 != ""))
    |> Enum.map(fn "v" <> n -> Version.parse!(n) end)
  end
end
