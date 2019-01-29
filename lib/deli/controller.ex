defmodule Deli.Controller do
  @moduledoc "Defines a behaviour for a service controller"

  @type env :: atom
  @type host :: String.t()

  @callback service_running?(env, host) :: boolean
  @callback service_status(env, host) :: String.t()
  @callback start_host(env, host) :: :ok | no_return
  @callback stop_host(env, host) :: :ok | no_return
  @callback restart_host(env, host) :: :ok | no_return
end
