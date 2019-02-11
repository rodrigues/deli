defmodule DeliCase do
  use ExUnit.CaseTemplate

  @moduledoc "Basic test case"

  using do
    quote do
      use ExUnitProperties
      import unquote(__MODULE__)
      import ExUnit.CaptureIO
      alias Deli.Config
    end
  end

  setup do
    put_config(:host_provider, Deli.HostProvider.Config)
  end

  def put_config(key, value) do
    :ok = :deli |> Application.put_env(key, value)
  end

  def delete_config(key) do
    :ok = :deli |> Application.delete_env(key)
  end

  def atom do
    :alphanumeric |> StreamData.atom()
  end

  def string do
    :alphanumeric |> StreamData.string()
  end

  def term_except(predicate) do
    StreamData.term() |> except(predicate)
  end

  def except(data, predicate) do
    data |> StreamData.filter(fn a -> not predicate.(a) end, 100_000)
  end
end
