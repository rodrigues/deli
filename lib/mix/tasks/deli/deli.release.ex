defmodule Mix.Tasks.Deli.Release do
  use Mix.Task
  import Deli.Shell
  alias Deli.{Config, Release, Versioning}

  @moduledoc """
  To build a release of current master into staging, do:

      $ mix deli.release

  Or, if you want to specify a version or target environment, do:

      $ mix deli.release --version=1.0.0 --target=prod

  You can also specify if you want assets to be included or not.
  It defaults to false, but you can change that in `config :deli, assets: true`

      $ mix deli -t prod -a
  """

  @shortdoc "Only builds application release (without deploy)"

  def run(args) do
    _ = Application.ensure_all_started(:deli)
    options = args |> parse_options

    if assets?(options), do: System.put_env("ASSETS", "1")

    tag = options |> Versioning.fetch_version_tag()
    target = options |> Keyword.fetch!(:target)

    Release.build(tag, target)
  end

  defp assets?(options) do
    if options |> Keyword.get(:assets) do
      true
    else
      Config.assets?()
    end
  end
end
