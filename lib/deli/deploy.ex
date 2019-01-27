defmodule Deli.Deploy do
  import Deli.Shell
  alias Deli.{Check, Config}

  @moduledoc false

  def run(target) do
    IO.puts("🤞")
    edeliver_target = target |> Config.edeliver_target()
    edeliver(:deploy, [:release, :to, edeliver_target])
    restart_target(target)
  end

  defp restart_target(target) do
    target |> Config.hosts() |> Enum.each(&restart_host/1)
  end

  defp restart_host(host) do
    app = Config.app()
    controller = Config.controller()
    id = "#{app}@#{host}"

    IO.puts("restarting #{id}...")
    :ok = app |> controller.restart_host(host)
    IO.puts([IO.ANSI.green(), "restarted #{id}", IO.ANSI.reset()])

    :timer.sleep(1_000)
    Check.run(host)
  end
end
