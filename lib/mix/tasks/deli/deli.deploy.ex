defmodule Mix.Tasks.Deli.Deploy do
  use Mix.Task
  import Deli.Shell
  alias Deli.{Config, Deploy, HostFilter}

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
    _ = Application.ensure_all_started(:deli)
    options = args |> parse_options
    target = options |> Keyword.fetch!(:target)

    {:ok, tag} =
      options[:version]
      |> Config.versioning().version_tag()

    IO.puts("version: #{tag}")

    {:ok, hosts} = target |> HostFilter.hosts(args)

    if :deploy |> confirm?(options) do
      IO.puts("🤞")
      hosts |> Enum.each(&Deploy.run(target, &1))
    else
      cancelled!(:deploy)
    end
  end
end
