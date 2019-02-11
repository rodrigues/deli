defmodule Deli.Ping do
  alias Deli.Check

  @moduledoc false

  def run(env, host, running_good? \\ true) do
    env |> Check.run(host, running_good?, Deli.Controller.Bin, :PONG)
  end
end
