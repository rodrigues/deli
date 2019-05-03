defmodule Deli.BeamVersions.File do
  alias Deli.{BeamVersions, Config}

  @moduledoc false

  @path "lib/deli/beam_versions/data.exs"

  @spec versions_from_file([BeamVersions.dep()]) :: BeamVersions.versions()
  def versions_from_file(deps \\ []) when is_list(deps) do
    code_handler = Config.__code_handler__()
    {%{} = versions, _} = code_handler.eval_file(@path)
    Enum.reduce(deps, versions, &Map.put_new(&2, &1, []))
  end

  @spec persist_versions(BeamVersions.versions()) :: :ok
  def persist_versions(versions) when is_map(versions) do
    file_handler = Config.__file_handler__()
    code_handler = Config.__code_handler__()

    content =
      versions
      |> inspect(limit: 1_000_000)
      |> code_handler.format_string!()
      |> IO.iodata_to_binary()

    file_handler.write!(@path, content, [])
  end
end
