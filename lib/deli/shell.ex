defmodule Deli.Shell do
  alias Deli.Config

  @moduledoc "Provides conveniences for modules to deal with shell commands and files"

  def cmd(command) do
    with 0 <- command |> verbose_inspect |> Mix.shell().cmd() do
      :ok
    else
      signal ->
        IO.puts([
          IO.ANSI.reset(),
          IO.ANSI.red_background(),
          IO.ANSI.white(),
          "Deploy command failed: `#{command}`",
          IO.ANSI.reset()
        ])

        exit({:shutdown, signal})
    end
  end

  def cmd_result(command) do
    command
    |> to_charlist
    |> verbose_inspect
    |> :os.cmd()
    |> to_string
    |> String.trim()
  end

  defp verbose_inspect(command) do
    if Config.verbose?() do
      IO.puts([
        IO.ANSI.bright(),
        "$ ",
        IO.ANSI.reset(),
        IO.ANSI.underline(),
        command,
        IO.ANSI.reset()
      ])
    end

    command
  end

  def edeliver(command) do
    cmd("mix edeliver #{command} --verbose")
  end

  def docker_compose(command) do
    no_tty = "COMPOSE_INTERACTIVE_NO_CLI=1"
    cmd("#{no_tty} docker-compose -f .deliver-docker-compose.yml #{command}")
  end

  def file_exists?(path) do
    path |> expand_path |> File.exists?()
  end

  def write_file(path, content, options \\ []) do
    path |> expand_path |> File.write!(content, options)
  end

  def expand_path(path) do
    path |> Path.expand(File.cwd!())
  end

  @spec error!(String.t()) :: no_return
  def error!(message) do
    Mix.shell().error(message)
    exit({:shutdown, 1})
  end
end
