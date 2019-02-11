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

  @versions @deps |> File.versions_from_file()

  @spec deps() :: [dep, ...]
  def deps, do: @deps

  @spec versions() :: versions
  def versions, do: @versions

  @spec fetch([opt]) :: [beam_version]
  def fetch(opts \\ []) do
    deps() |> Enum.map(&fetch_version({&1, opts[&1]}))
  end

  defp fetch_version({dep, nil}) when dep in @deps do
    {dep, :latest} |> fetch_version
  end

  defp fetch_version({dep, :latest}) when dep in @deps do
    {version, _} =
      @versions[dep]
      |> Enum.find(fn {v, _} -> not String.contains?(v, "rc") end)

    {dep, version} |> fetch_version
  end

  defp fetch_version({dep, version}) when dep in @deps and is_binary(version) do
    {_, checksum} = @versions[dep] |> Enum.find(fn {v, _} -> v == version end)

    if checksum do
      {dep, version, checksum} |> fetch_version
    else
      raise """
        Dependency #{dep} does not have version #{version} configured.

        Try updating `deli`:

            `$ mix deps.update deli`
      """
    end
  end

  defp fetch_version({dep, version, checksum})
       when dep in @deps and is_binary(version) and is_binary(checksum) do
    {dep, version: version, checksum: checksum}
  end
end
