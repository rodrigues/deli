defmodule Deli.Checker do
  @callback check_service_status(app :: atom, host :: String.t()) :: :ok
end
