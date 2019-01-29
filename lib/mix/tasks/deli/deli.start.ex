defmodule Mix.Tasks.Deli.Start do
  use Mix.Task
  import Deli.Shell
  alias Deli.{Check, Config}

  @moduledoc """
  To start app in all staging hosts, do:

      $ mix deli.start

  To target prod, do:

      $ mix deli.start -t prod

  It will ask for confirmation before start.

  If you don't want that extra step, pass `--yes`, or simply `-y` when calling it:

      $ mix deli.start -t prod -y
  """

  @shortdoc "Starts application"

  def run(args) do
    _ = Application.ensure_all_started(:deli)
    app = Config.app()
    options = args |> parse_options
    target = options |> Keyword.fetch!(:target)

    if "start #{app} at target #{target}?" |> confirm?(options) do
      target |> Config.hosts() |> Enum.each(&start_host(target, &1))
    else
      IO.puts([IO.ANSI.green(), "start cancelled by user", IO.ANSI.reset()])
    end
  end

  defp start_host(env, host) do
    controller = Config.controller()
    id = env |> Config.host_id(host)

    Check.run(env, host, false)
    IO.puts("starting #{id}...")
    :ok = env |> controller.start_host(host)
    IO.puts([IO.ANSI.green(), "started #{id}", IO.ANSI.reset()])

    :timer.sleep(1_000)
    Check.run(env, host)
  end
end
