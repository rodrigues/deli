defmodule Deli.HostProvider do
  @moduledoc "Defines a behaviour for a host provider"

  @doc "Hosts for given env"
  @callback hosts(env :: Deli.env()) :: [Deli.host()]
end
