defmodule TestAgent do
  use Agent

  @moduledoc false

  @initial_state %{}

  def start_link do
    Agent.start_link(fn -> @initial_state end, name: __MODULE__)
  end

  @spec clear() :: :ok
  def clear do
    Agent.update(__MODULE__, fn _ -> @initial_state end)
  end

  @spec get(atom, term) :: term
  def get(key, default \\ nil) when is_atom(key) do
    __MODULE__ |> Agent.get(& &1) |> Map.get(key, default)
  end

  @spec set(atom, term) :: :ok
  def set(key, value) when is_atom(key) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end
end
