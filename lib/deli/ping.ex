defmodule Deli.Ping do
  alias Deli.Check

  @moduledoc false

  def run(env, host) do
    running_good? = true
    env |> Check.run(host, running_good?, Deli.Controller.Bin, :pong)
  end
end
