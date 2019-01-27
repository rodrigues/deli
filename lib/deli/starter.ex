defmodule Deli.Starter do
  @callback restart_host(app :: atom, target :: atom, host :: String.t()) :: :ok | no_return
end
