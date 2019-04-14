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
    _ = :deli |> ensure_all_started
    options = args |> parse_options
    target = options |> Keyword.fetch!(:target)
    {:ok, hosts} = target |> Config.host_filter().hosts(args)
    hosts |> Enum.each(&check.run(target, &1))
  end
end
