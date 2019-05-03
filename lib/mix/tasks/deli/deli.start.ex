defmodule Mix.Tasks.Deli.Start do
  use Mix.Task
  import Deli.Shell
  alias Deli.Config

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

  @impl true
  def run(args) do
    _ = ensure_all_started(:deli)
    options = parse_options(args)
    target = Keyword.fetch!(options, :target)
    {:ok, hosts} = Config.host_filter().hosts(target, args)

    if confirm?(:start, options) do
      Enum.each(hosts, &start_host(target, &1))
    else
      cancelled!(:start)
    end
  end

  defp start_host(env, host) do
    check = Config.check()
    controller = Config.controller()
    id = Config.host_id(env, host)

    check.run(env, host, false)
    IO.puts("starting #{id}...")
    :ok = controller.start_host(env, host)
    IO.puts([IO.ANSI.green(), "started #{id}", IO.ANSI.reset()])

    :timer.sleep(Config.wait(:started_check))
    check.run(env, host)
  end
end
