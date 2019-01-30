defmodule Deli.Versioning do
  @moduledoc "Defines a behaviour for versioning"

  @doc """
  Receives the version informed by user on CLI, or `nil`.
  Runs any versioning policy wanted for the project,
  returns an ok tuple with the version tag to be used during deploy,
  or raises in case there is no version tag resolved.
  """
  @callback version_tag(String.t() | nil) :: {:ok, String.t()} | no_return
end
