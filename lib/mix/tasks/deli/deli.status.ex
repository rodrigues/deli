defmodule Mix.Tasks.Deli.Status do
  use Mix.Task
  import Deli.Shell
  alias Deli.Config

  @moduledoc """
  To check status app in all staging hosts, do:

      $ mix deli.status

  To target prod, do:

      $ mix deli.status -t prod
  """

  @shortdoc "Checks application status"

  @impl true
  def run(args) do
    check = Config.check()
    _ = ensure_all_started(:deli)
    options = parse_options(args)
    target = Keyword.fetch!(options, :target)
    {:ok, hosts} = Config.host_filter().hosts(target, args)
    Enum.each(hosts, &check.run(target, &1))
  end
end
