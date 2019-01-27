defmodule Mix.Tasks.Deli.Shell do
  use Mix.Task
  import Deli.Shell
  alias Deli.Config

  @moduledoc """
  Returns the command you need to run to open a shell.

  In bash: `eval $(mix deli.shell)`.
  In fish: `eval (mix deli.shell)`.
  """

  @shortdoc "Provides shell command to run remote console"

  def run(args) do
    _ = Application.ensure_all_started(:deli)

    options = args |> parse_options
    target = options |> Keyword.fetch!(:target)

    Application.put_env(:deli, :verbose, true)
    app = Config.app()

    # Build a host selector
    host = target |> Config.hosts() |> Enum.at(0)

    IO.write("ssh #{app}@#{host} #{Config.bin_path()} remote_console")
  end
end
