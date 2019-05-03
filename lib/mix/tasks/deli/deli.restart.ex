defmodule Mix.Tasks.Deli.Restart do
  use Mix.Task
  import Deli.Shell
  alias Deli.Config

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
    _ = ensure_all_started(:deli)
    options = parse_options(args)
    target = Keyword.fetch!(options, :target)
    {:ok, hosts} = Config.host_filter().hosts(target, args)

    if confirm?(:restart, options) do
      Enum.each(hosts, &restart_host(target, &1))
    else
      cancelled!(:restart)
    end
  end

  defp restart_host(env, host) do
    check = Config.check()
    controller = Config.controller()
    id = Config.host_id(env, host)

    check.run(env, host)
    IO.puts("restarting #{id}...")
    :ok = controller.restart_host(env, host)
    IO.puts([IO.ANSI.green(), "restarted #{id}", IO.ANSI.reset()])

    :timer.sleep(Config.wait(:started_check))
    check.run(env, host)
  end
end
