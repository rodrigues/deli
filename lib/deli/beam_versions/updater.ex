defmodule Deli.BeamVersions.Updater do
  alias Deli.{BeamVersions, Config}
  alias Deli.BeamVersions.File

  @moduledoc false

  @http_apps ~w(
    inets
    ssl
  )a

  @base_uri "https://github.com"
  @api "https://api.github.com/repos"
  @archive_path "src.tar.gz"

  @headers [
    {'User-Agent', 'Delibot/0.2 (+https://github.com/rodrigues/deli)'},
    {'Accepts', 'application/vnd.github.v3+json'}
  ]

  @repos %{
    otp: "erlang/otp",
    elixir: "elixir-lang/elixir",
    rebar3: "erlang/rebar3"
  }

  @archives %{
    otp: "OTP-%v.tar.gz",
    elixir: "v%v.tar.gz",
    rebar3: "%v.tar.gz"
  }

  @min_versions %{
    otp: "20",
    elixir: "1.8",
    rebar3: "3.6.1"
  }

  @spec update() :: :ok
  def update do
    Enum.each(BeamVersions.deps(), &update/1)
  end

  @spec update(BeamVersions.dep()) :: :ok
  def update(dep) do
    Enum.each(@http_apps, &Application.ensure_all_started/1)

    current_versions = Enum.map(BeamVersions.versions()[dep], &elem(&1, 0))
    new_version? = fn v -> not Enum.member?(current_versions, v) end

    dep
    |> releases()
    |> Enum.filter(&supported_version?(dep, &1))
    |> Enum.filter(new_version?)
    |> Enum.each(&add_version(dep, &1))
  end

  defp add_version(dep, version) do
    IO.puts("Download #{dep}@#{version}...")
    {_, 0} = download_version(dep, version)
    :ok = append_version(dep, version, checksum())
  end

  defp download_version(dep, version) do
    file = String.replace(@archives[dep], "%v", version)
    uri = "#{@base_uri}/#{@repos[dep]}/archive/#{file}"
    system().cmd("curl", ["-fSL#", uri, "-o", @archive_path])
  end

  defp checksum do
    {result, 0} = system().cmd("shasum", ["-a", "256", @archive_path])
    result |> String.split(" ") |> Enum.at(0)
  end

  defp append_version(dep, version, checksum) do
    versions = File.versions_from_file()
    new_dep_versions = [{version, checksum} | versions[dep]]

    versions
    |> Map.put(dep, new_dep_versions)
    |> File.persist_versions()
  end

  defp releases(dep) do
    uri = '#{@api}/#{@repos[dep]}/tags'
    releases(dep, uri, [])
  end

  defp releases(dep, uri, acc) do
    {:ok, {{_, 200, _}, headers, json}} = :httpc.request(:get, {uri, @headers}, [], [])

    versions = json |> Jason.decode!() |> Enum.flat_map(&release_versions(dep, &1))
    acc = versions ++ acc
    link = Enum.find(headers, fn {k, _} -> k == 'link' end)

    if link do
      {_, content} = link
      content = to_string(content)

      if String.contains?(content, ~s(rel="next")) do
        next =
          content
          |> String.split(~s(; rel="next"), parts: 2)
          |> Enum.at(0)
          |> String.split("<")
          |> List.last()
          |> String.split(">", parts: 2)
          |> Enum.at(0)
          |> to_charlist()

        releases(dep, next, acc)
      else
        acc
      end
    else
      acc
    end
  end

  defp release_versions(dep, %{"name" => tag}) when is_binary(tag) do
    case tag_version(dep, tag) do
      nil ->
        []

      version ->
        [version]
    end
  end

  defp tag_version(:otp, "OTP-" <> version), do: version
  defp tag_version(:elixir, "v" <> version), do: version
  defp tag_version(:rebar3, version), do: version
  defp tag_version(_, _), do: nil

  defp supported_version?(dep, version) do
    min = generic_version(@min_versions[dep])
    version = generic_version(version)
    generic_version_compare(version, min) != :lt
  end

  defp generic_version(version) do
    version
    |> String.split("-")
    |> Enum.at(0)
    |> String.split(".")
    |> Enum.map(&generic_version_number/1)
  end

  defp generic_version_number(number) do
    {integer, ""} = Integer.parse(number)
    integer
  end

  defp generic_version_compare([], []), do: :eq
  defp generic_version_compare([_v1 | _r1], []), do: :gt
  defp generic_version_compare([], [_v2 | _r2]), do: :lt
  defp generic_version_compare([v1], [v1]), do: :eq
  defp generic_version_compare([v1], [v2]) when v1 > v2, do: :gt
  defp generic_version_compare([v1], [v2]) when v1 < v2, do: :lt

  defp generic_version_compare([v1 | r1], [v1 | r2]) do
    generic_version_compare(r1, r2)
  end

  defp generic_version_compare([v1 | _r1], [v2 | _r2]) when v1 > v2, do: :gt
  defp generic_version_compare([v1 | _r1], [v2 | _r2]) when v1 < v2, do: :lt

  defp system, do: Config.__system_handler__()
end
