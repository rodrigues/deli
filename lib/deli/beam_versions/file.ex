defmodule Deli.BeamVersions.File do
  alias Deli.BeamVersions
  alias Deli.Config

  @moduledoc false

  @path "lib/deli/beam_versions/data.exs"

  @spec versions_from_file([BeamVersions.dep()]) :: BeamVersions.versions()
  def versions_from_file(deps \\ []) do
    code_handler = Config.__code_handler__()
    {%{} = versions, _} = @path |> code_handler.eval_file()
    deps |> Enum.reduce(versions, &Map.put_new(&2, &1, []))
  end

  @spec persist_versions(BeamVersions.versions()) :: :ok
  def persist_versions(versions) do
    file_handler = Config.__file_handler__()
    code_handler = Config.__code_handler__()

    content =
      versions
      |> inspect(limit: 1_000_000)
      |> code_handler.format_string!()
      |> IO.iodata_to_binary()

    @path |> file_handler.write!(content)
  end
end
