defmodule Deli.Deploy do
  import Deli.Shell
  alias Deli.Config

  @moduledoc false

  def run(target) do
    IO.puts("🤞")
    edeliver_target = target |> Config.edeliver_target()
    edeliver("deploy release to #{edeliver_target}")
    restart_target(target)
    edeliver("ping #{edeliver_target}")
  end

  defp restart_target(target) do
    target |> Config.hosts() |> Enum.each(&restart_host/1)
  end

  defp restart_host(host) do
    app = Config.app()
    controller = Config.controller()
    id = "#{app}@#{host}"

    IO.puts("restarting #{id}")
    :ok = app |> controller.restart_host(host)
    IO.puts("restarted #{id}")

    :timer.sleep(1_000)

    if app |> controller.service_running?(host) do
      IO.puts([IO.ANSI.green(), "running #{id}", IO.ANSI.reset()])
    else
      IO.puts([IO.ANSI.red(), "not running #{id}", IO.ANSI.reset()])
      IO.puts(app |> controller.service_status(host))
    end
  end
end
