defmodule Deli.HostProvider do
  @moduledoc "Defines a behaviour for a host provider"

  @doc "A list or stream of `Deli.host()` for given env"
  @callback hosts(Deli.env()) :: Enumerable.t()

  @doc "Total count of hosts available for the provided env"
  @callback count(Deli.env()) :: non_neg_integer | :infinity
end
