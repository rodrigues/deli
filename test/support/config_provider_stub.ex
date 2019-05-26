defmodule ConfigProviderStub do
  import TestAgent, only: [get: 1, get: 2]

  @moduledoc false

  def get_env(:deli, key, default \\ nil) do
    if get(:use_application_config) do
      Application.get_env(:deli, key, default)
    else
      get({:config, key}, default)
    end
  end

  def put_env(:deli, key, value) do
    if get(:use_application_config) do
      Application.put_env(:deli, key, value)
    else
      TestAgent.set({:config, key}, value)
    end
  end

  def delete_env(:deli, key) do
    if get(:use_application_config) do
      Application.delete_env(:deli, key)
    else
      TestAgent.delete({:config, key})
    end
  end
end
