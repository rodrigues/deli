defmodule Deli.Controller.Systemctl do
  import Deli.Shell
  alias Deli.Config

  @moduledoc "Provides support for systemd on deploy"

  @behaviour Deli.Controller

  @impl true
  def start_host(env, host) do
    sudo_systemctl(env, host, :start)
  end

  @impl true
  def stop_host(env, host) do
    sudo_systemctl(env, host, :stop)
  end

  @impl true
  def restart_host(env, host) do
    sudo_systemctl(env, host, :restart)
  end

  @impl true
  def service_running?(env, host) do
    service_status(env, host) =~ ~r/Active\: active \(running\)/
  end

  @impl true
  def service_status(env, host) do
    [command | args] = env |> systemctl(host, :status)
    {:ok, result} = command |> cmd_result(args, [0, 3])
    result
  end

  defp sudo_systemctl(env, host, op) do
    [command | args] = env |> systemctl(host, op, true)
    cmd(command, args)
  end

  defp systemctl(env, host, cmd, sudo \\ false) do
    sudo = if sudo, do: :sudo
    [:ssh, Config.host_id(env, host), sudo, :systemctl, cmd, Config.app()]
  end
end
