defmodule Mix.Tasks.Deli.Ping do
  use Mix.Task
  import Deli.Shell
  alias Deli.{Config, Ping}

  @moduledoc """
  To ping app in all staging hosts, do:

      $ mix deli.ping

  To target prod, do:

      $ mix deli.ping -t prod
  """

  @shortdoc "Pings application"

  @impl true
  def run(args) do
    _ = ensure_all_started(:deli)
    options = parse_options(args)
    target = Keyword.fetch!(options, :target)
    {:ok, hosts} = Config.host_filter().hosts(target, args)
    Enum.each(hosts, &Ping.run(target, &1))
  end
end
