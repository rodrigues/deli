defmodule StreamGenerators do
  import ExUnitProperties
  import StreamData

  @moduledoc false

  @limit_mismatches 100_000

  def app, do: atom()
  def env, do: atom()

  def app_user do
    [atom(), binary()] |> one_of()
  end

  def host do
    :alphanumeric
    |> string(max_length: 20)
    |> except(&(&1 == ""))
  end

  def hosts do
    host()
    |> list_of(max_length: 3)
    |> nonempty()
  end

  def version do
    gen all major <- 0..128 |> integer(),
            minor <- 0..256 |> integer(),
            patch <- 0..512 |> integer() do
      "#{major}.#{minor}.#{patch}"
    end
  end

  def atom do
    :alphanumeric |> atom()
  end

  def string do
    :alphanumeric |> string()
  end

  def nonempty_string(type \\ :alphanumeric) do
    type |> string() |> except(&empty_string?/1)
  end

  def term_except(predicate) do
    term() |> except(predicate)
  end

  def except(data, predicate) do
    data |> filter(&(not predicate.(&1)), @limit_mismatches)
  end

  defp empty_string?(""), do: true
  defp empty_string?(_), do: false
end
