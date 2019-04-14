defmodule Deli.Deploy do
  @moduledoc "Defines a behaviour for deploy"

  @callback run(Deli.env(), Deli.host()) :: :ok
end
