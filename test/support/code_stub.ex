defmodule CodeStub do
  import TestAgent, only: [get: 1, get: 2]

  @moduledoc false

  def eval_file(path) do
    call = {:__code_handler__, :eval_file, path}
    send(get(:pid), call)
    default = fn _ -> {%{}, []} end
    get(:eval_file, default).(path)
  end

  def format_string!(content) do
    call = {:__code_handler__, :format_string!, content}
    send(get(:pid), call)
    get(:format_string!, & &1).(content)
  end
end
