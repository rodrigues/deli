defmodule Deli.BeamVersions do
  alias Deli.BeamVersions.File

  @moduledoc false

  @deps ~w(otp elixir rebar3)a

  @type dep :: :otp | :elixir | :rebar3
  @type version :: String.t()
  @type checksum :: String.t()
  @type opt :: {dep, version} | {dep, version, checksum}
  @type beam_version :: {dep, [{:version, version} | {:checksum, checksum}]}
  @type versions :: %{required(dep) => [{version(), checksum()}]}

  @versions File.versions_from_file(@deps)

  defguardp is_dep(dep) when dep in @deps

  @spec deps() :: [dep, ...]
  def deps, do: @deps

  @spec versions() :: versions
  def versions, do: @versions

  @spec fetch([opt]) :: [beam_version]
  def fetch(opts \\ []) when is_list(opts) do
    Enum.map(deps(), &fetch_version({&1, opts[&1]}))
  end

  defp fetch_version({dep, nil}) when is_dep(dep) do
    fetch_version({dep, :latest})
  end

  defp fetch_version({dep, :latest}) when is_dep(dep) do
    {version, _} = Enum.find(@versions[dep], fn {v, _} -> not String.contains?(v, "rc") end)
    fetch_version({dep, version})
  end

  defp fetch_version({dep, version}) when is_dep(dep) and is_binary(version) do
    case Enum.find(@versions[dep], fn {v, _} -> v == version end) do
      {_, checksum} when is_binary(checksum) ->
        fetch_version({dep, version, checksum})

      _ ->
        raise """
          Dependency #{dep} does not have version #{version} configured.

          Try updating `deli`:

              `$ mix deps.update deli`
        """
    end
  end

  defp fetch_version({dep, version, checksum})
       when is_dep(dep) and is_binary(version) and is_binary(checksum) do
    {dep, version: version, checksum: checksum}
  end
end
