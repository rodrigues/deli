defmodule Deli.Controller.Systemctl do
  import Deli.Shell

  @moduledoc "Provides support for systemd on deploy"

  @behaviour Deli.Controller

  @impl true
  def start_host(app, host) do
    sudo_systemctl(app, host, :start)
  end

  @impl true
  def stop_host(app, host) do
    sudo_systemctl(app, host, :stop)
  end

  @impl true
  def restart_host(app, host) do
    sudo_systemctl(app, host, :restart)
  end

  @impl true
  def service_running?(app, host) do
    status = app |> service_status(host)
    status =~ ~r/Active\: active \(running\)/
  end

  @impl true
  def service_status(app, host) do
    {:ok, result} = app |> systemctl(host, :status)
    result
  end

  defp sudo_systemctl(app, host, op) do
    [command | args] = app |> systemctl(host, op, true)
    cmd(command, args)
  end

  defp systemctl(app, host, cmd, sudo \\ false) do
    sudo = if sudo, do: "sudo ", else: ""
    [:ssh, "#{app}@#{host}", "'#{sudo}systemctl #{cmd} #{app}'"]
  end
end
