defmodule Mix.Tasks.Deli.Stop do
  use Mix.Task
  import Deli.Shell
  alias Deli.{Check, Config}

  @moduledoc """
  To stop app in all staging hosts, do:

      $ mix deli.stop

  To target prod, do:

      $ mix deli.stop -t prod

  It will ask for confirmation before stop.

  If you don't want that extra step, pass `--yes`, or simply `-y` when calling it:

      $ mix deli.stop -t prod -y
  """

  @shortdoc "Stops application"

  def run(args) do
    _ = Application.ensure_all_started(:deli)
    app = Config.app()
    options = args |> parse_options
    target = options |> Keyword.get(:target, "staging")

    if "stop #{app} at target #{target}?" |> confirm?(options) do
      target |> Config.hosts() |> Enum.each(&stop_host/1)
    else
      IO.puts([IO.ANSI.green(), "stop cancelled by user", IO.ANSI.reset()])
    end
  end

  defp stop_host(host) do
    app = Config.app()
    controller = Config.controller()
    id = "#{app}@#{host}"

    Check.run(host)
    IO.puts("stopping #{id}...")
    :ok = app |> controller.stop_host(host)
    IO.puts([IO.ANSI.green(), "stopped #{id}", IO.ANSI.reset()])

    :timer.sleep(1_000)
    Check.run(host, false)
  end
end
