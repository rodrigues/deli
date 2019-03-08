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

  @impl true
  def run(args) do
    _ = :deli |> ensure_all_started
    options = args |> parse_options
    target = options |> Keyword.fetch!(:target)
    {:ok, hosts} = target |> Config.host_filter().hosts(args)

    if :start |> confirm?(options) do
      hosts |> Enum.each(&start_host(target, &1))
    else
      cancelled!(:start)
    end
  end

  defp start_host(env, host) do
    controller = Config.controller()
    id = env |> Config.host_id(host)

    Check.run(env, host, false)
    IO.puts("starting #{id}...")
    :ok = env |> controller.start_host(host)
    IO.puts([IO.ANSI.green(), "started #{id}", IO.ANSI.reset()])

    :timer.sleep(Config.wait(:started_check))
    Check.run(env, host)
  end
end
