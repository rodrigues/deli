defmodule Mix.Tasks.Deli.Release do
  use Mix.Task
  import Deli.Shell
  alias Deli.Config

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

  @impl true
  def run(args) do
    _ = ensure_all_started(:deli)
    system = Config.__system_handler__()
    options = parse_options(args)
    target = Keyword.fetch!(options, :target)

    if assets?(options), do: system.put_env("ASSETS", "1")

    {:ok, tag} = Config.versioning().version_tag(options[:version])

    Config.release().build(tag, target)
  end

  defp assets?(options) do
    options[:assets] || Config.assets?()
  end
end
