defmodule Deli.Check do
  alias Deli.Config

  @moduledoc false

  def run(host, running_good? \\ true) do
    app = Config.app()
    controller = Config.controller()
    id = "#{app}@#{host}"

    running_color = if running_good?, do: IO.ANSI.green(), else: IO.ANSI.red()
    not_running_color = if running_good?, do: IO.ANSI.red(), else: IO.ANSI.green()

    if app |> controller.service_running?(host) do
      IO.puts([running_color, "running #{id}", IO.ANSI.reset()])

      unless running_good? do
        IO.puts(app |> controller.service_status(host))
      end
    else
      IO.puts([not_running_color, "not running #{id}", IO.ANSI.reset()])

      if running_good? do
        IO.puts(app |> controller.service_status(host))
      end
    end
  end
end
