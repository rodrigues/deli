defmodule StreamGenerators do
  import ExUnitProperties
  import StreamData

  @moduledoc false

  @limit_mismatches 100_000

  def app, do: strict_atom()

  def app_user do
    [strict_atom(), nonempty_string()] |> one_of()
  end

  def bin_path, do: path()

  def cmd, do: nonempty_string()

  def cmd_args, do: nonempty_string() |> list_of()

  def cmd_with_args, do: tuple({cmd(), cmd_args()})

  def env, do: strict_atom()

  def host do
    :alphanumeric
    |> string(max_length: 20)
    |> except(&(&1 == "" || &1 =~ "@"))
  end

  def hosts do
    host()
    |> list_of(max_length: 3)
    |> nonempty()
  end

  def path do
    gen all parts <- nonempty_string() |> list_of() |> nonempty() do
      "/#{parts |> Enum.join("/")}"
    end
  end

  def port, do: 0..65_535 |> integer()

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

  def strict_atom do
    atom() |> except(&(not strict_atom?(&1)))
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

  defp strict_atom?(nil), do: false
  defp strict_atom?(:_), do: false

  defp strict_atom?(atom) when is_atom(atom) do
    not (to_string(atom) =~ "@")
  end
end
