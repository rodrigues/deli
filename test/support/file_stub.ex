defmodule FileStub do
  import TestAgent, only: [get: 1, get: 2]

  @moduledoc false

  def read!(path) do
    call = {:__file_handler__, :read!, path}
    send(get(:pid), call)
    default = fn _ -> "" end
    get(:read!, default).(path)
  end

  def write!(path, content) do
    call = {:__system__, :_write!, path, content}
    send(get(:pid), call)
    default = fn _, _ -> :ok end
    get(:write!, default).(path, content)
  end
end
