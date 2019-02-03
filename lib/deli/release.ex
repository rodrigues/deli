defmodule Deli.Release do
  alias Deli.Versioning

  @moduledoc "Defines a behaviour for releases"

  @doc "Creates a release targeting `target` env on `tag`"
  @callback build(tag :: Versioning.tag(), target :: Deli.env()) :: :ok
end
