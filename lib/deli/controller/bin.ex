defmodule Deli.Controller.Bin do
  import Deli.Shell

  @moduledoc "Provides support for bin on deploy"

  @behaviour Deli.Controller

  @impl true
  def start_host(app, host) do
    bin_cmd(app, host, :start)
  end

  @impl true
  def stop_host(app, host) do
    bin_cmd(app, host, :stop)
  end

  @impl true
  def restart_host(app, host) do
    bin_cmd(app, host, :restart)
  end

  @impl true
  def service_running?(app, host) do
    status = app |> service_status(host)
    status =~ ~r/pong/
  end

  @impl true
  def service_status(app, host) do
    [command | args] = app |> bin(host, :ping)
    {:ok, content} = command |> cmd_result(args, [0, 127])
    content
  end

  defp bin_cmd(app, host, op) do
    [command | args] = app |> bin(host, op)
    cmd(command, args)
  end

  defp bin(app, host, cmd) do
    [:ssh, "#{app}@#{host}", "'/opt/#{app}/bin/#{app} #{cmd}'"]
  end
end
