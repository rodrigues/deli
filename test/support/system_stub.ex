defmodule SystemStub do
  import TestAgent, only: [get: 1, get: 2]

  @moduledoc false

  def cmd(command, args, opts) do
    call = {:__system__, command, args, opts}
    send(get(:pid), call)

    {get(:content, ""), get(:signal, 0)}
  end
end
