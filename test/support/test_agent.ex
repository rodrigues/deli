defmodule TestAgent do
  use Agent

  @moduledoc false

  @initial_state %{}

  def start_link do
    Agent.start_link(fn -> @initial_state end)
  end

  @spec clear() :: :ok
  def clear do
    Agent.update(current_test_agent(), fn _ -> @initial_state end)
  end

  @spec get(term, term) :: term
  def get(key, default \\ nil) do
    current_test_agent() |> Agent.get(& &1) |> Map.get(key, default)
  end

  @spec set(term, term) :: :ok
  def set(key, value) do
    Agent.update(current_test_agent(), &Map.put(&1, key, value))
  end

  @spec delete(term) :: :ok
  def delete(key) do
    Agent.update(current_test_agent(), &Map.delete(&1, key))
  end

  defp current_test_agent do
    case :erlang.get(:test_agent_pid) do
      pid when is_pid(pid) ->
        pid

      :undefined ->
        [parent_pid | _] = :erlang.get(:"$ancestors")
        {:dictionary, list} = Process.info(parent_pid, :dictionary)
        Keyword.get(list, :test_agent_pid)
    end
  end
end
