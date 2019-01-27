defmodule Deli.Controller.Systemctl do
  import Deli.Shell

  @moduledoc "Provides support for systemd on deploy"

  @behaviour Deli.Controller

  @impl true
  def restart_host(app, host) do
    cmd("ssh #{app}@#{host} 'sudo systemctl restart #{app}'")
  end

  @impl true
  def service_running?(app, host) do
    status = app |> service_status(host)
    status =~ ~r/Active\: active \(running\)/
  end

  @impl true
  def service_status(app, host) do
    "ssh #{app}@#{host} 'systemctl status #{app}'" |> cmd_result
  end
end
