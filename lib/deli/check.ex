defmodule Deli.Check do
  alias Deli.Config

  @moduledoc false

  def run(env, host, running_good? \\ true) do
    controller = Config.controller()
    id = env |> Config.host_id(host)

    running_color = if running_good?, do: IO.ANSI.green(), else: IO.ANSI.red()
    not_running_color = if running_good?, do: IO.ANSI.red(), else: IO.ANSI.green()

    if env |> controller.service_running?(host) do
      IO.puts([running_color, "running #{id}", IO.ANSI.reset()])

      if not running_good? || Config.verbose?() do
        IO.puts(env |> controller.service_status(host))
      end
    else
      IO.puts([not_running_color, "not running #{id}", IO.ANSI.reset()])

      if running_good? || Config.verbose?() do
        IO.puts(env |> controller.service_status(host))
      end
    end
  end
end
