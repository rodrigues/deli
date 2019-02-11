defmodule Deli.BeamVersions.File do
  alias Deli.BeamVersions

  @moduledoc false

  @path "lib/deli/beam_versions/data.exs"

  @spec versions_from_file([BeamVersions.dep()]) :: BeamVersions.versions()
  def versions_from_file(deps \\ []) do
    {%{} = versions, _} = @path |> Code.eval_file()
    deps |> Enum.reduce(versions, &Map.put_new(&2, &1, []))
  end

  @spec persist_versions(BeamVersions.versions()) :: :ok
  def persist_versions(versions) do
    content =
      versions
      |> inspect(limit: 1_000_000)
      |> Code.format_string!()
      |> IO.iodata_to_binary()

    @path |> File.write!(content)
  end
end
