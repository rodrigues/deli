defmodule Mix.Tasks.Deli.Deploy do
  use Mix.Task
  alias Deli.{Deploy, Versioning}

  @moduledoc """
  To deploy current master into staging, do:

      $ mix deli.deploy

  Or, if you want to specify a version or target environment, do:

      $ mix deli.deploy --version=1.0.0 --target=prod

  It will ask for confirmation before it starts.

  If you don't want that extra step, pass `--yes`, or simply `-y` when calling it:

      $ mix deli.deploy -t prod -y
  """

  @shortdoc "Only deploys application (without release build)"

  def run(args) do
    _ = Application.ensure_all_started(:deli)
    options = args |> parse_options

    tag = options |> Versioning.fetch_version_tag()
    target = options |> Keyword.get(:target, "staging")

    if confirm_deploy?(tag, target, options) do
      Deploy.run(target)
    else
      IO.puts([IO.ANSI.green(), "deploy cancelled by user", IO.ANSI.reset()])
    end
  end

  defp confirm_deploy?(tag, target, options) do
    message = "deploy #{tag} to #{target}?"

    if options |> Keyword.get(:yes) do
      IO.puts("#{message} (Y/n) YES")
      true
    else
      message |> Mix.shell().yes?()
    end
  end

  defp parse_options(args) do
    options = [version: :string, target: :string, yes: :boolean]
    aliases = [v: :version, t: :target, y: :yes]

    args
    |> OptionParser.parse(aliases: aliases, switches: options)
    |> elem(0)
  end
end
