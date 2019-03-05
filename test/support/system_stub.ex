defmodule SystemStub do
  import TestAgent, only: [get: 1, get: 2]

  @moduledoc false

  def cmd(command, args, opts) do
    call = {:__system_handler__, :cmd, command, args, opts}
    send(get(:pid), call)
    default = fn _, _, _ -> {"", 0} end
    get(:cmd, default).(command, args, opts)
  end

  def put_env(varname, value) do
    call = {:__system_handler__, :put_env, varname, value}
    send(get(:pid), call)
    default = fn _, _ -> :ok end
    get(:put_env, default).(varname, value)
  end
end
