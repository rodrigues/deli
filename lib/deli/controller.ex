defmodule Deli.Controller do
  @moduledoc "Defines a behaviour for a service controller"
  @callback service_running?(app :: atom, host :: String.t()) :: boolean
  @callback service_status(app :: atom, host :: String.t()) :: String.t()
  @callback restart_host(app :: atom, host :: String.t()) :: :ok | no_return
end
