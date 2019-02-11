defmodule DeliCase do
  use ExUnit.CaseTemplate

  @moduledoc "Basic test case"

  @limit_mismatches 100_000

  using do
    quote do
      use ExUnitProperties
      import unquote(__MODULE__)
      import ExUnit.CaptureIO
      alias Deli.Config
    end
  end

  setup do
    put_config(:__system__, System)
    put_config(:__file_handler__, File)
    put_config(:__code_handler__, Code)
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
    data |> StreamData.filter(&(not predicate.(&1)), @limit_mismatches)
  end
end
