defmodule FileStub do
  import TestAgent, only: [get: 1, get: 2]

  @moduledoc false

  def read!(path) do
    call = {:__file_handler__, :read!, path}
    send(get(:pid), call)
    default = fn _ -> "" end
    get(:read!, default).(path)
  end

  def write!(path, content, opts) do
    call = {:__file_handler__, :write!, path, content, opts}
    send(get(:pid), call)
    default = fn _, _ -> :ok end
    get(:write!, default).(path, content)
  end

  def exists?(path) do
    call = {:__file_handler__, :exists?, path}
    send(get(:pid), call)
    default = fn _ -> true end
    get(:exists?, default).(path)
  end

  def cwd! do
    call = {:__file_handler__, :cwd!}
    send(get(:pid), call)
    default = fn -> "/home/deli/" end
    get(:cwd!, default).()
  end
end
