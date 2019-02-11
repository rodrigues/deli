defmodule DeliCase do
  use ExUnit.CaseTemplate

  @moduledoc "Basic test case"

  using do
    quote do
      use ExUnitProperties
      import unquote(__MODULE__)
      import ExUnit.CaptureIO
      alias Deli.Config

      def atom, do: :alphanumeric |> atom
    end
  end

  def put_config(key, value) do
    :ok = :deli |> Application.put_env(key, value)
  end

  def delete_config(key) do
    :ok = :deli |> Application.delete_env(key)
  end

  def term_except(predicate) do
    StreamData.term()
    |> StreamData.filter(fn a -> not predicate.(a) end, 100_000)
  end
end
