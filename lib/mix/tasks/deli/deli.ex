defmodule Mix.Tasks.Deli do
  use Mix.Task
  alias Mix.Tasks.Deli.{Deploy, Release}

  @moduledoc """
  To do a full deploy from current master into staging, do:

      $ mix deli

  Or, if you want to specify a version or target environment, do:

      $ mix deli --version=1.0.0 --target=prod

  It will ask for confirmation after release is built, before deploy.

  If you don't want that extra step, pass `--yes`, or simply `-y` when calling it:

      $ mix deli -t prod -y

  You can also specify if you want assets to be included or not.
  It defaults to false, but you can change that in `config :deli, assets: true`

      $ mix deli -t prod -a -y

  See Deli docs for more: https://hexdocs.pm/deli
  """

  @shortdoc "Deploys application full-cycle"

  def run(args) do
    _ = Application.ensure_all_started(:deli)

    with :ok <- args |> Release.run() do
      Deploy.run(args)
    end
  end
end
