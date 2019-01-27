defmodule Deli.Controllers.Systemctl do
  import Deli.Shell

  @behaviour Deli.Starter
  @behaviour Deli.Checker

  @impl Deli.Starter
  def restart_host(app, _target, host) do
    id = "#{app}@#{host}"
    IO.puts("restarting #{id}")
    cmd("ssh #{id} 'sudo systemctl restart #{app}'")
    IO.puts("restarted #{id}")
  end

  @impl Deli.Checker
  def check_service_status(app, host) do
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
