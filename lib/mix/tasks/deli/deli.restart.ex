defmodule Mix.Tasks.Deli.Restart do
  use Mix.Task
  import Deli.Shell
  alias Deli.{Check, Config, HostFilter}

  @moduledoc """
  To restart app in all staging hosts, do:

      $ mix deli.restart

  To target prod, do:

      $ mix deli.restart -t prod

  It will ask for confirmation before restart.

  If you don't want that extra step, pass `--yes`, or simply `-y` when calling it:

      $ mix deli.restart -t prod -y
  """

  @shortdoc "Restarts application"

  @impl true
  def run(args) do
    _ = Application.ensure_all_started(:deli)
    options = args |> parse_options
    target = options |> Keyword.fetch!(:target)
    {:ok, hosts} = target |> HostFilter.hosts(args)

    if :restart |> confirm?(options) do
      hosts |> Enum.each(&restart_host(target, &1))
    else
      cancelled!(:restart)
    end
  end

  defp restart_host(env, host) do
    controller = Config.controller()
    id = env |> Config.host_id(host)

    Check.run(env, host)
    IO.puts("restarting #{id}...")
    :ok = env |> controller.restart_host(host)
    IO.puts([IO.ANSI.green(), "restarted #{id}", IO.ANSI.reset()])

    :timer.sleep(Config.wait(:started_check))
    Check.run(env, host)
  end
end
