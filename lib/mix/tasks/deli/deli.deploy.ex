defmodule Mix.Tasks.Deli.Deploy do
  use Mix.Task
  import Deli.Shell
  alias Deli.Config

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

  @impl true
  def run(args) do
    _ = ensure_all_started(:deli)
    options = parse_options(args)
    target = Keyword.fetch!(options, :target)

    deploy = Config.deploy()
    host_filter = Config.host_filter()
    versioning = Config.versioning()

    {:ok, tag} = versioning.version_tag(options[:version])

    IO.puts("version: #{tag}")

    {:ok, hosts} = host_filter.hosts(target, args)

    if confirm?(:deploy, options) do
      IO.puts("🤞")
      Enum.each(hosts, &deploy.run(target, &1))
    else
      cancelled!(:deploy)
    end
  end
end
