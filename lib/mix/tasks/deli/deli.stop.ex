defmodule Mix.Tasks.Deli.Stop do
  use Mix.Task
  import Deli.Shell
  alias Deli.Config

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

  @impl true
  def run(args) do
    _ = :deli |> ensure_all_started
    options = args |> parse_options
    target = options |> Keyword.fetch!(:target)
    {:ok, hosts} = target |> Config.host_filter().hosts(args)

    if :stop |> confirm?(options) do
      hosts |> Enum.each(&stop_host(target, &1))
    else
      cancelled!(:stop)
    end
  end

  defp stop_host(env, host) do
    check = Config.check()
    controller = Config.controller()
    id = env |> Config.host_id(host)

    check.run(env, host)
    IO.puts("stopping #{id}...")
    :ok = env |> controller.stop_host(host)
    IO.puts([IO.ANSI.green(), "stopped #{id}", IO.ANSI.reset()])

    :timer.sleep(Config.wait(:stopped_check))
    check.run(env, host, false)
  end
end
