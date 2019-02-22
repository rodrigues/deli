defmodule Mix.Tasks.Deli.Version do
  use Mix.Task
  import Deli.Shell
  alias Deli.{Config, HostFilter}

  @moduledoc """
  To check version app in all staging hosts, do:

      $ mix deli.version

  To target prod, do:

      $ mix deli.version -t prod
  """

  @shortdoc "Checks application version"

  @impl true
  def run(args) do
    _ = Application.ensure_all_started(:deli)

    target = args |> parse_options |> Keyword.fetch!(:target)
    opts = args |> parse_extra_options

    if opts[:compare] do
      compare_versions(target, args)
    else
      check_version(target, args)
    end
  end

  defp check_version(:dev, _args) do
    app = Config.app()
    IO.puts("checking version of #{app} at dev environment")
    version = Config.version()
    print_version(version)
  end

  defp check_version(env, args) do
    {:ok, hosts} = env |> HostFilter.hosts(args)
    app = Config.app()

    IO.puts("checking version of #{app} at target #{env}")
    hosts |> Enum.each(&print_host_version(env, &1))
  end

  defp compare_versions(env, args) do
    {:ok, hosts} = env |> HostFilter.hosts(args)
    hosts |> Enum.each(&compare_host_version(env, &1))
  end

  defp compare_host_version(env, host) do
    {:ok, version} = env |> host_version(host)
    local = Config.version()

    case local |> Version.compare(version) do
      :lt ->
        IO.puts([
          IO.ANSI.bright(),
          "* #{host} ",
          IO.ANSI.reset(),
          IO.ANSI.red(),
          IO.ANSI.underline(),
          "ahead",
          IO.ANSI.reset(),
          IO.ANSI.bright(),
          "  (#{version}, local #{local})",
          IO.ANSI.reset()
        ])

      :gt ->
        IO.puts([
          IO.ANSI.bright(),
          "* #{host} ",
          IO.ANSI.reset(),
          IO.ANSI.red(),
          IO.ANSI.underline(),
          "outdated",
          IO.ANSI.reset(),
          IO.ANSI.bright(),
          "  (#{version}, local #{local})",
          IO.ANSI.reset()
        ])

      :eq ->
        IO.puts([
          IO.ANSI.bright(),
          "* #{host} ",
          IO.ANSI.reset(),
          IO.ANSI.green(),
          "up-to-date",
          IO.ANSI.reset(),
          IO.ANSI.faint(),
          "  (#{version})",
          IO.ANSI.reset()
        ])
    end
  end

  defp print_host_version(env, host) do
    with {:ok, version} <- env |> host_version(host) do
      print_version(version)
    else
      {:error, error} ->
        IO.puts([IO.ANSI.red(), inspect(error), IO.ANSI.reset()])
    end
  end

  defp print_version(version) do
    IO.puts([IO.ANSI.green(), to_string(version), IO.ANSI.reset()])
  end

  defp host_version(env, host) do
    app = Config.app()
    app_user = env |> Config.app_user()
    code = ~s|":application.get_key(:#{app}, :vsn)"|
    args = ["#{app_user}@#{host}", Config.bin_path(), :rpc, code]
    {:ok, result} = :ssh |> cmd_result(args)

    case result do
      "{:ok, '" <> rest ->
        version = rest |> String.split("'", parts: 2) |> Enum.at(0) |> Version.parse!()
        {:ok, version}

      other ->
        {:error, other}
    end
  end

  defp parse_extra_options(args) do
    args
    |> OptionParser.parse(aliases: [c: :compare], switches: [compare: :boolean])
    |> elem(0)
  end
end
