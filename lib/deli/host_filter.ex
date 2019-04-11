defmodule Deli.HostFilter do
  @moduledoc "Defines a behaviour for a host filter"

  @callback hosts(env :: Deli.env(), argv :: OptionParser.argv()) :: {:ok, [Deli.host()]}
  @callback host(env :: Deli.env(), argv :: OptionParser.argv()) ::
              {:ok, Deli.host()} | {:error, term}
end
