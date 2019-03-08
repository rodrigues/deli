defmodule Deli.HostFilter do
  @moduledoc "Defines a behaviour for a host filter"

  @callback hosts(Deli.env(), OptionParser.argv()) :: {:ok, [Deli.host()]}
  @callback host(Deli.env(), OptionParser.argv()) :: {:ok, Deli.host()} | {:error, term}
end
