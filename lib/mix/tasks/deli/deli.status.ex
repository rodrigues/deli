defmodule Mix.Tasks.Deli.Status do
  use Mix.Task
  import Deli.Shell
  alias Deli.{Check, HostFilter}

  @moduledoc """
  To check status app in all staging hosts, do:

      $ mix deli.status

  To target prod, do:

      $ mix deli.status -t prod
  """

  @shortdoc "Checks application status"

  @impl true
  def run(args) do
    _ = Application.ensure_all_started(:deli)
    options = args |> parse_options
    target = options |> Keyword.fetch!(:target)
    {:ok, hosts} = target |> HostFilter.hosts(args)
    hosts |> Enum.each(&Check.run(target, &1))
  end
end
