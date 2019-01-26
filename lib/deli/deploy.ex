defmodule Deli.Deploy do
  import Deli.Shell
  alias Deli.Config

  @moduledoc false

  def run(target) do
    IO.puts("🤞")
    edeliver("deploy release to #{target}")
    restart_target(target)
    edeliver("ping #{target}")
  end

  defp restart_target(target) do
    target |> Config.hosts() |> Enum.each(&restart_target(target, &1))
  end

  defp restart_target(target, host) do
    app = Config.app()

    IO.puts("restarting...")
    cmd("ssh #{app}@#{host} 'sudo systemctl restart #{app}'")
    IO.puts("restarted.")

    :timer.sleep(1_000)

    if service_active?(host), do: edeliver("ping #{target}")
  end

  defp service_active?(host) do
    app = Config.app()
    status = "ssh #{app}@#{host} 'systemctl status #{app}'" |> cmd_result

    if status =~ ~r/Active\: active \(running\)/ do
      IO.puts([IO.ANSI.green(), "#{app} running", IO.ANSI.reset()])
      true
    else
      IO.puts([IO.ANSI.red(), "#{app} not running", IO.ANSI.reset()])
      IO.puts(status)
      false
    end
  end
end
