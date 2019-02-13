defmodule Mix.Tasks.Deli.Ping do
  use Mix.Task
  import Deli.Shell
  alias Deli.{HostFilter, Ping}

  @moduledoc """
  To ping app in all staging hosts, do:

      $ mix deli.ping

  To target prod, do:

      $ mix deli.ping -t prod
  """

  @shortdoc "Pings application"

  def run(args) do
    _ = Application.ensure_all_started(:deli)
    options = args |> parse_options
    target = options |> Keyword.fetch!(:target)
    {:ok, hosts} = target |> HostFilter.hosts(args)
    hosts |> Enum.each(&Ping.run(target, &1))
  end
end
