defmodule Mix.Tasks.Deli.Status do
  use Mix.Task
  import Deli.Shell
  alias Deli.{Check, Config}

  @moduledoc """
  To check status app in all staging hosts, do:

      $ mix deli.status

  To target prod, do:

      $ mix deli.status -t prod
  """

  @shortdoc "Checks application status"

  def run(args) do
    _ = Application.ensure_all_started(:deli)
    app = Config.app()
    options = args |> parse_options
    target = options |> Keyword.fetch!(:target)

    IO.puts("checking status of #{app} at target #{target}")
    target |> Config.hosts() |> Enum.each(&Check.run(target, &1))
  end
end
