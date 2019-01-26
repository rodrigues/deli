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
    target |> Config.hosts() |> Enum.each(&restart_host/1)
  end

  defp restart_host(host) do
    app = Config.app()
    id = "#{app}@#{host}"

    IO.puts("restarting #{id}")
    cmd("ssh #{id} 'sudo systemctl restart #{id}'")
    IO.puts("restarted #{id}")

    :timer.sleep(1_000)
    check_service_status(host)
  end

  defp check_service_status(host) do
    app = Config.app()
    id = "#{app}@#{host}"
    status = "ssh #{id} 'systemctl status #{app}'" |> cmd_result

    if status =~ ~r/Active\: active \(running\)/ do
      IO.puts([IO.ANSI.green(), "running #{id}", IO.ANSI.reset()])
      true
    else
      IO.puts([IO.ANSI.red(), "not running #{id}", IO.ANSI.reset()])
      IO.puts(status)
      false
    end
  end
end
