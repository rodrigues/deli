defmodule Deli.Controller.Bin do
  import Deli.Shell
  alias Deli.Config

  @moduledoc "Provides support for bin on deploy"

  @behaviour Deli.Controller

  @impl true
  def start_host(env, host) do
    bin_cmd(env, host, :start)
  end

  @impl true
  def stop_host(env, host) do
    bin_cmd(env, host, :stop)
  end

  @impl true
  def restart_host(env, host) do
    bin_cmd(env, host, :restart)
  end

  @impl true
  def service_running?(env, host) do
    service_status(env, host) =~ ~r/pong/
  end

  @impl true
  def service_status(env, host) do
    [command | args] = env |> bin(host, :ping)
    {:ok, content} = command |> cmd_result(args, [0, 1, 127])
    content
  end

  defp bin_cmd(env, host, op) do
    [command | args] = env |> bin(host, op)
    cmd(command, args)
  end

  defp bin(env, host, cmd) do
    [:ssh, Config.host_id(env, host), Config.bin_path(), cmd]
  end
end
