defmodule Deli.Shell do
  alias Deli.Config

  @moduledoc false

  # When you want the output, use `cmd_result`
  def cmd(command, args \\ [], ok_signals \\ [0], opts \\ []) do
    command = command |> to_string
    args = args |> Enum.map(&to_string/1)
    # verbose_inspect([command | args])

    result? = opts |> Keyword.get(:result)
    opts = opts |> Keyword.delete(:result)

    {content, signal} = command |> System.cmd(args, verbose_opts(opts))

    if ok_signals |> Enum.member?(signal) do
      if result?, do: {:ok, content}, else: :ok
    else
      command_failed!(command, args, signal, content)
    end
  end

  def cmd_result(command, args \\ [], ok_signals \\ [0], opts \\ []) do
    opts = [result: true, into: ""] ++ opts
    cmd(command, args, ok_signals, opts)
  end

  def edeliver(command, args \\ []) do
    verbose = if Config.verbose?(), do: ["--verbose"], else: []
    edeliver_args = ["edeliver", command] ++ args ++ verbose
    "mix" |> cmd(edeliver_args)
  end

  def docker_compose(command, args \\ [], ok_signals \\ [0]) do
    args = ["-f", ".deliver-docker-compose.yml"] ++ [command] ++ args
    env = [{"COMPOSE_INTERACTIVE_NO_CLI", "1"}]
    "docker-compose" |> cmd(args, ok_signals, env: env)
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

  def confirm?(message, options) do
    if options |> Keyword.get(:yes) do
      IO.puts("#{message} (Y/n) YES")
      true
    else
      message |> Mix.shell().yes?()
    end
  end

  def parse_options(args) do
    options = [version: :string, target: :string, yes: :boolean, assets: :boolean]
    aliases = [v: :version, t: :target, y: :yes, a: :assets]

    args
    |> OptionParser.parse(aliases: aliases, switches: options)
    |> elem(0)
    |> ensure_target
  end

  defp ensure_target(opts) do
    target = opts |> Keyword.get(:target, Config.default_target()) |> Config.mix_env()
    opts |> Keyword.put(:target, target)
  end

  defp command_failed!(command, args, signal, content)
       when is_binary(command) and is_list(args) and is_integer(signal) do
    details = "(#{signal})"
    details = if content, do: "\n#{details} #{content}", else: details

    IO.puts([
      IO.ANSI.reset(),
      IO.ANSI.red_background(),
      IO.ANSI.white(),
      "Deploy command failed: `#{command_inspect([command | args])}`",
      IO.ANSI.reset(),
      details
    ])

    exit({:shutdown, signal})
  end

  # defp verbose_inspect(command) do
  #   if Config.verbose?() do
  #     IO.puts([
  #       IO.ANSI.bright(),
  #       "$ ",
  #       IO.ANSI.reset(),
  #       IO.ANSI.underline(),
  #       command_inspect(command),
  #       IO.ANSI.reset()
  #     ])
  #   end
  #   command
  # end

  defp verbose_opts(opts) do
    if Config.verbose?() do
      [into: IO.stream(:stdio, :line), stderr_to_stdout: true] ++ opts
    else
      opts ++ [into: ""]
    end
  end

  defp command_inspect(command) when is_binary(command), do: command
  defp command_inspect(command) when is_list(command), do: command |> Enum.join(" ")
end
