defmodule Deli.Ping do
  alias Deli.Config

  @moduledoc false

  @spec run(Deli.env(), Deli.host()) :: :ok
  def run(env, host) do
    check = Config.check()
    running_good? = true
    env |> check.run(host, running_good?, Deli.Controller.Bin, :pong)
  end
end
