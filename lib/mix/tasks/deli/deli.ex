defmodule Mix.Tasks.Deli do
  use Mix.Task
  alias Deli.{Deploy, Release, Versioning}

  @moduledoc """
  To deploy current master into staging, do:

      $ mix deli

  Or, if you want to specify a version or target environment, do:

      $ mix deli --version=1.0.0 --target=prod

  It will ask for confirmation after release is built, before deploy.

  If you don't want that extra step, pass `--yes`, or simply `-y` when calling it:

      $ mix deli -t prod -y

  You can also specify if you want assets to be included or not.
  It defaults to false, but you can change that in `config :deli, assets: true`

      $ mix deli -t prod -a -y
  """

  @shortdoc "Deploys application"

  def run(args) do
    Application.ensure_all_started(:deli)
    options = args |> parse_options

    if assets?(options), do: System.put_env("ASSETS", "1")

    tag = options |> Versioning.fetch_version_tag()
    target = options |> Keyword.get(:target, "staging")

    Release.build(tag, target)

    if confirm_deploy?(tag, target, options) do
      Deploy.run(target)
    else
      IO.puts([IO.ANSI.green(), "Deploy aborted by user", IO.ANSI.reset()])
    end
  end

  defp confirm_deploy?(tag, target, options) do
    message = "Deploy #{tag} to #{target}?"

    if options |> Keyword.get(:yes) do
      IO.puts("#{message} (Y/n) YES")
      true
    else
      message |> Mix.shell().yes?()
    end
  end

  defp assets?(options) do
    if options |> Keyword.get(:assets) do
      true
    else
      :deli |> Application.get_env(:assets, false)
    end
  end

  defp parse_options(args) do
    options = [version: :string, target: :string, assets: :boolean, yes: :boolean]
    aliases = [v: :version, t: :target, a: :assets, y: :yes]

    args
    |> OptionParser.parse(aliases: aliases, switches: options)
    |> elem(0)
  end
end
