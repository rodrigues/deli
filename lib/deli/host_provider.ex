defmodule Deli.HostProvider do
  @moduledoc "Defines a behaviour for a host provider"

  @doc "A list of hosts for given env"
  @callback hosts(Deli.env()) :: [Deli.host()]

  @doc "Total count of hosts available for the provided env"
  @callback count(Deli.env()) :: non_neg_integer | :infinity
end
