defmodule ApplicationStub do
  import TestAgent, only: [get: 1, get: 2]

  @moduledoc false

  def ensure_all_started(app) do
    call = {:__application_handler__, :ensure_all_started, app}
    send(get(:pid), call)
    default = fn app -> {:ok, [app]} end
    get(:ensure_all_started, default).(app)
  end
end
