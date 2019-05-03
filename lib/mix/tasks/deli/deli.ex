defmodule Mix.Tasks.Deli do
  use Mix.Task
  import Deli.Shell
  alias Deli.Config
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

  @impl true
  def run(args) do
    _ = ensure_all_started(:deli)
    options = parse_options(args)
    target = Keyword.fetch!(options, :target)

    # Although deploy is the one that needs hosts,
    # calling this before so operation stops fast
    # in case there are no valid hosts given filter
    {:ok, _} = Config.host_filter().hosts(target, args)
    :ok = Release.run(args)
    Deploy.run(args)
  end
end
