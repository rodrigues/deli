defmodule Mix.Tasks.Deli.Restart do
  use Mix.Task
  alias Deli.{Check, Config}

  @moduledoc """
  To restart app in all staging hosts, do:

      $ mix deli.restart

  To target prod, do:

      $ mix deli.restart -t prod

  It will ask for confirmation before restart.

  If you don't want that extra step, pass `--yes`, or simply `-y` when calling it:

      $ mix deli.restart -t prod -y
  """

  @shortdoc "Restarts application"

  def run(args) do
    _ = Application.ensure_all_started(:deli)
    options = args |> parse_options
    target = options |> Keyword.get(:target, "staging")

    if confirm_restart?(target, options) do
      target |> Config.hosts() |> Enum.each(&restart_host/1)
    else
      IO.puts([IO.ANSI.green(), "restart cancelled by user", IO.ANSI.reset()])
    end
  end

  defp restart_host(host) do
    app = Config.app()
    controller = Config.controller()
    id = "#{app}@#{host}"

    Check.run(host, false)
    IO.puts("restarting #{id}...")
    :ok = app |> controller.restart_host(host)
    IO.puts([IO.ANSI.green(), "restarted #{id}", IO.ANSI.reset()])

    :timer.sleep(1_000)
    Check.run(host)
  end

  defp confirm_restart?(target, options) do
    message = "restart #{Config.app()} #{target}?"

    if options |> Keyword.get(:yes) do
      IO.puts("#{message} (Y/n) YES")
      true
    else
      message |> Mix.shell().yes?()
    end
  end

  defp parse_options(args) do
    options = [target: :string, yes: :boolean]
    aliases = [t: :target, y: :yes]

    args
    |> OptionParser.parse(aliases: aliases, switches: options)
    |> elem(0)
  end
end
