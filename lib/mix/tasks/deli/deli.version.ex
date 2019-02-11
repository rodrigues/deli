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

  def run(args) do
    _ = Application.ensure_all_started(:deli)

    args
    |> parse_options
    |> Keyword.fetch!(:target)
    |> check_version(args)
  end

  defp check_version(:dev, _args) do
    app = Config.app()
    IO.puts("checking version of #{app} at dev environment")
    version = Config.version()
    IO.puts([IO.ANSI.green(), to_string(version), IO.ANSI.reset()])
  end

  defp check_version(env, args) do
    {:ok, hosts} = env |> HostFilter.hosts(args)
    app = Config.app()

    IO.puts("checking version of #{app} at target #{env}")
    hosts |> Enum.each(&host_version/1)
  end

  defp host_version(host) do
    app = Config.app()
    code = ~s|":application.get_key(:#{app}, :vsn)"|
    args = ["#{app}@#{host}", Config.bin_path(), :rpc, code]
    {:ok, result} = :ssh |> cmd_result(args)

    case result do
      "{:ok, '" <> rest ->
        version = rest |> String.split("'") |> Enum.at(0)
        IO.puts([IO.ANSI.green(), version, IO.ANSI.reset()])

      other ->
        IO.puts([IO.ANSI.red(), other, IO.ANSI.reset()])
    end
  end
end
