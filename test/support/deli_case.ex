defmodule DeliCase do
  use ExUnit.CaseTemplate

  @moduledoc "Basic test case"

  using do
    quote do
      use ExUnitProperties
      import StreamDataExclude
      import unquote(__MODULE__)
      alias Deli.Config
    end
  end

  def put_config(key, value) do
    :ok = :deli |> Application.put_env(key, value)
  end

  def delete_config(key) do
    :ok = :deli |> Application.delete_env(key)
  end
end
