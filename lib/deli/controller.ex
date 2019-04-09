defmodule Deli.Controller do
  @moduledoc "Defines a behaviour for a service controller"

  @callback service_running?(env :: Deli.env(), host :: Deli.host()) :: boolean
  @callback service_status(env :: Deli.env(), host :: Deli.host()) :: String.t()
  @callback start_host(env :: Deli.env(), host :: Deli.host()) :: :ok
  @callback stop_host(env :: Deli.env(), host :: Deli.host()) :: :ok
  @callback restart_host(env :: Deli.env(), host :: Deli.host()) :: :ok
end
