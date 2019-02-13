defmodule Deli.Config.Ensure do
  @moduledoc false

  def ensure_boolean(b) when b in [true, false], do: b
  def ensure_boolean(x), do: raise("Only boolean accepted, got: #{inspect(x)}")

  def ensure_atom(a) when is_atom(a), do: a
  def ensure_atom(x), do: raise("Only atom accepted, got: #{inspect(x)}")

  def ensure_port_number(i) when i in 0..65_535, do: i
  def ensure_port_number(x), do: raise("Only port number accepted, got: #{inspect(x)}")

  def ensure_pos_integer(i) when is_integer(i) and i > 0, do: i
  def ensure_pos_integer(x), do: raise("Only positive integer accepted, got: #{inspect(x)}")

  def ensure_binary(s) when is_binary(s), do: s
  def ensure_binary(x), do: raise("Only string accepted, got: #{inspect(x)}")

  def ensure_atom_or_binary(x) when is_atom(x) or is_binary(x), do: x
  def ensure_atom_or_binary(x), do: raise("Only string or atom accepted, got: #{inspect(x)}")
end
