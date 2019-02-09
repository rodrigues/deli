defmodule Deli.BeamVersions.Updater do
  alias Deli.BeamVersions

  @moduledoc false

  @http_apps ~w(
    inets
    ssl
  )a

  @base_uri "https://github.com"
  @api "https://api.github.com/repos"

  @headers [
    {'User-Agent', 'Delibot/0.1 (+https://github.com/rodrigues/deli)'},
    {'Accepts', 'application/json'}
  ]

  @repos %{
    otp: "erlang/otp",
    elixir: "elixir-lang/elixir",
    rebar3: "erlang/rebar3"
  }

  @archive_path "src.tar.gz"

  @archives %{
    otp: "OTP-%v.tar.gz",
    elixir: "v%v.tar.gz",
    rebar3: "%v.tar.gz"
  }

  @spec update() :: :ok
  def update do
    BeamVersions.deps() |> Enum.each(&update/1)
  end

  @spec update(BeamVersions.dep()) :: :ok
  def update(dep) do
    @http_apps |> Enum.each(&Application.ensure_all_started/1)

    current_versions = BeamVersions.versions()[dep]
    new_version? = fn v -> current_versions |> Enum.all?(&(elem(&1, 0) != v)) end

    dep
    |> releases()
    |> Enum.filter(new_version?)
    |> Enum.each(&add_version(dep, &1))
  end

  defp add_version(dep, version) do
    download_version(dep, version)
    sum = dep |> checksum(version)
    append_version(dep, version, sum)
  end

  defp download_version(dep, version) do
    file = @archives[dep] |> String.replace("%v", version)
    uri = "#{@base_uri}/#{@repos[dep]}/archive/#{file}"
    {_, 0} = "curl" |> System.cmd(["-fSL#", uri, "-o", @archive_path])
  end

  defp checksum(dep, version) do
    {result, 0} = "shasum" |> System.cmd(["-a", "256", @path])
    result |> String.split(" ") |> Enum.at(0)
  end

  defp append_version(dep, version, checksum) do
    # load file, append, and persist
  end

  defp releases(dep) do
    uri = '#{@api}/#{@repos[dep]}/releases'
    dep |> releases(uri, [])
  end

  defp releases(dep, uri, acc) do
    {:ok, {{_, 200, _}, headers, json}} =
      :get
      |> :httpc.request({uri, @headers}, [], [])

    versions = json |> Jason.decode!() |> Enum.map(&release_version(dep, &1))
    acc = versions ++ acc
    link = headers |> Enum.find(fn {k, _} -> k == 'link' end)

    if link do
      {_, content} = link

      next =
        content
        |> to_string
        |> String.split(";", trim: true)
        |> Enum.find(&String.starts_with?(&1, ~s(rel="next")))

      if next do
        next_uri =
          next
          |> String.split("<", parts: 2)
          |> Enum.at(1)
          |> String.split(">", parts: 2)
          |> Enum.at(0)

        dep |> releases(next_uri, acc)
      else
        acc
      end
    else
      acc
    end
  end

  defp release_version(dep, %{"tag_name" => tag}) when is_binary(tag) do
    dep |> process_tag(tag)
  end

  defp process_tag(:otp, "OTP-" <> version), do: version
  defp process_tag(:elixir, "v" <> version), do: version
  defp process_tag(:rebar3, version), do: version
end
