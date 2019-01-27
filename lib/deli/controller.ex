defmodule Deli.Controller do
  @moduledoc "Defines a behaviour for a service controller"

  @type app :: atom
  @type host :: String.t()

  @callback service_running?(app, host) :: boolean
  @callback service_status(app, host) :: String.t()
  @callback start_host(app, host) :: :ok | no_return
  @callback stop_host(app, host) :: :ok | no_return
  @callback restart_host(app, host) :: :ok | no_return
end
