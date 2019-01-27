defmodule Mix.Tasks.Deli.Start do
  use Mix.Task
  alias Deli.{Check, Config}

  @moduledoc """
  To start app in all staging hosts, do:

      $ mix deli.start

  To target prod, do:

      $ mix deli.start -t prod

  It will ask for confirmation before start.

  If you don't want that extra step, pass `--yes`, or simply `-y` when calling it:

      $ mix deli.start -t prod -y
  """

  @shortdoc "Starts application"

  def run(args) do
    _ = Application.ensure_all_started(:deli)
    options = args |> parse_options
    target = options |> Keyword.get(:target, "staging")

    if confirm_start?(target, options) do
      target |> Config.hosts() |> Enum.each(&start_host/1)
    else
      IO.puts([IO.ANSI.green(), "start cancelled by user", IO.ANSI.reset()])
    end
  end

  defp start_host(host) do
    app = Config.app()
    controller = Config.controller()
    id = "#{app}@#{host}"

    Check.run(host, false)
    IO.puts("starting #{id}...")
    :ok = app |> controller.start_host(host)
    IO.puts([IO.ANSI.green(), "started #{id}", IO.ANSI.reset()])

    :timer.sleep(1_000)
    Check.run(host)
  end

  defp confirm_start?(target, options) do
    message = "start #{Config.app()} #{target}?"

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
