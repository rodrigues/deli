defmodule Mix.Tasks.Deli.Deploy do
  use Mix.Task
  import Deli.Shell
  alias Deli.{Config, Deploy, Versioning}

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
    app = Config.app()
    options = args |> parse_options
    target = options |> Keyword.fetch!(:target)
    tag = options |> Versioning.fetch_version_tag()

    if "deploy #{app}#{tag} to #{target}?" |> confirm?(options) do
      Deploy.run(target)
    else
      IO.puts([IO.ANSI.green(), "deploy cancelled by user", IO.ANSI.reset()])
    end
  end
end
