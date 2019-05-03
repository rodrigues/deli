defmodule Deli.Check.Default do
  alias Deli.Config

  @moduledoc false

  @behaviour Deli.Check

  @impl true
  def run(env, host, running_good? \\ true, controller \\ nil, action \\ :running) do
    controller = controller || Config.controller()
    id = Config.host_id(env, host)

    running_color = if running_good?, do: IO.ANSI.green(), else: IO.ANSI.red()
    not_running_color = if running_good?, do: IO.ANSI.red(), else: IO.ANSI.green()

    if controller.service_running?(env, host) do
      IO.puts([running_color, "#{action} #{id}", IO.ANSI.reset()])

      if not running_good? || Config.verbose?() do
        IO.puts(controller.service_status(env, host))
      end
    else
      IO.puts([not_running_color, "not #{action} #{id}", IO.ANSI.reset()])

      if running_good? || Config.verbose?() do
        IO.puts(controller.service_status(env, host))
      end
    end

    :ok
  end
end
