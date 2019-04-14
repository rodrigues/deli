defmodule Deli.Check do
  @moduledoc "Defines a behaviour for service check"

  @type env :: Deli.env()
  @type host :: Deli.host()
  @type running_good? :: boolean
  @type controller :: module | nil
  @type action :: atom

  @callback run(env, host) :: :ok
  @callback run(env, host, running_good?) :: :ok
  @callback run(env, host, running_good?, controller) :: :ok
  @callback run(env, host, running_good?, controller, action) :: :ok
end
