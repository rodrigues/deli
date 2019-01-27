defmodule Deli.Versioning do
  import Deli.Shell

  @moduledoc "Provides version git tag enforcing"

  def fetch_version_tag(options) when is_list(options) do
    options
    |> Keyword.get(:version)
    |> fetch_version_tag
  end

  def fetch_version_tag(nil) do
    version = Mix.Project.get().project[:version] |> Version.parse!()
    tag = git_tags() |> List.last()
    action = if tag, do: {:compare, version, tag}, else: {:create, version}
    action |> fetch_version_tag
  end

  def fetch_version_tag("v" <> version), do: version |> fetch_version_tag

  def fetch_version_tag(version) when is_binary(version) do
    sanitized_version = version |> Version.parse!() |> to_string
    "v#{sanitized_version}"
  end

  def fetch_version_tag({:compare, version, tag}) do
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

  def fetch_version_tag({:create, version}) do
    version |> create_version_tag
  end

  defp create_version_tag(version) do
    tag = "v#{version}"
    cmd(:git, [:tag, tag])
    cmd(:git, [:push, :origin, tag])
    tag
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
