defmodule StreamGenerators do
  import ExUnitProperties
  import StreamData

  @moduledoc false

  @limit_mismatches 100_000

  def app, do: strict_atom()

  def app_user do
    one_of([strict_atom(), nonempty_string()])
  end

  def bin_path, do: path()

  def cmd, do: nonempty_string()

  def cmd_args, do: list_of(nonempty_string())

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
      "/#{Enum.join(parts, "/")}"
    end
  end

  def port, do: integer(0..65_535)

  def signal, do: integer(1..500)

  def signal(signals) do
    signals |> Enum.map(&constant/1) |> one_of()
  end

  def version do
    gen all major <- integer(0..128),
            minor <- integer(0..256),
            patch <- integer(0..512) do
      "#{major}.#{minor}.#{patch}"
    end
  end

  def atom, do: atom(:alphanumeric)

  def strict_atom do
    except(atom(), &(not strict_atom?(&1)))
  end

  def string, do: string(:alphanumeric)

  def nonempty_string(type \\ :alphanumeric) do
    type |> string() |> except(&empty_string?/1)
  end

  def term_except(predicate) do
    except(term(), predicate)
  end

  def except(data, predicate) do
    filter(data, &(not predicate.(&1)), @limit_mismatches)
  end

  defp empty_string?(""), do: true
  defp empty_string?(_), do: false

  defp strict_atom?(nil), do: false
  defp strict_atom?(:_), do: false

  defp strict_atom?(atom) when is_atom(atom) do
    not (to_string(atom) =~ "@")
  end
end
