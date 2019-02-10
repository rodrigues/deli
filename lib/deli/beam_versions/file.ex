defmodule Deli.BeamVersions.File do
  @moduledoc false

  @path "lib/deli/beam_versions/data.exs"

  def versions_from_file(deps \\ []) do
    {%{} = versions, _} = @path |> Code.eval_file()
    deps |> Enum.reduce(versions, &Map.put_new(&2, &1, []))
  end

  def persist_versions(versions) do
    content =
      versions
      |> inspect(limit: 1_000_000)
      |> Code.format_string!()
      |> IO.iodata_to_binary()

    @path |> File.write(content)
  end
end
