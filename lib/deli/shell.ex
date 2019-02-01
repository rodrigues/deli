defmodule Deli.Shell do
  alias Deli.Config

  @moduledoc false

  @type command :: atom | String.t()
  @type args :: [String.Chars.t()]
  @type exit_signal :: non_neg_integer
  @type ok_signals :: [exit_signal]

  @spec cmd(command, args, ok_signals, Keyword.t()) :: :ok
  def cmd(command, args \\ [], ok_signals \\ [0], opts \\ []) do
    command |> do_cmd(args, ok_signals, opts)
  end

  @spec cmd_result(command, args, ok_signals, Keyword.t()) ::
          {:ok, Collectable.t()}
  def cmd_result(command, args \\ [], ok_signals \\ [0], opts \\ []) do
    opts = [into: ""] ++ opts
    command |> do_cmd(args, ok_signals, opts, true)
  end

  defp do_cmd(command, args, ok_signals, opts, result? \\ false) do
    command = command |> to_string
    args = args |> Enum.map(&to_string/1)
    verbose_inspect([command | args])

    {content, signal} = command |> System.cmd(args, verbose_opts(opts))

    if ok_signals |> Enum.member?(signal) do
      if result?, do: {:ok, content}, else: :ok
    else
      command_failed!(command, args, signal, content)
    end
  end

  @spec edeliver(command, args) :: :ok
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

  def confirm?(operation, options) do
    app = Config.app()
    target = options |> Keyword.fetch!(:target)
    message = "#{operation} #{app} at #{target}?"

    if options[:yes] do
      IO.puts("#{message} (Y/n) YES")
      true
    else
      message |> Mix.shell().yes?()
    end
  end

  def cancelled!(operation) do
    IO.puts([
      IO.ANSI.green(),
      to_string(operation),
      " cancelled by user",
      IO.ANSI.reset()
    ])
  end

  def parse_options(args) do
    options = [
      version: :string,
      target: :string,
      yes: :boolean,
      assets: :boolean
    ]

    aliases = [
      v: :version,
      t: :target,
      y: :yes,
      a: :assets
    ]

    args
    |> OptionParser.parse(aliases: aliases, switches: options)
    |> elem(0)
    |> ensure_target
  end

  defp ensure_target(opts) do
    target = opts |> Keyword.get(:target, Config.default_target()) |> Config.mix_env()
    opts |> Keyword.put(:target, target)
  end

  @spec command_failed!(command, args, exit_signal, Collectable.t()) :: no_return
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

  defp verbose_inspect(command) do
    if Config.output_commands?() do
      IO.puts([
        IO.ANSI.bright(),
        "$ ",
        IO.ANSI.reset(),
        IO.ANSI.underline(),
        command_inspect(command),
        IO.ANSI.reset()
      ])
    end

    :ok
  end

  @spec verbose_opts(Keyword.t()) :: Keyword.t()
  defp verbose_opts(opts) do
    if Config.verbose?() do
      [into: IO.stream(:stdio, :line), stderr_to_stdout: true] ++ opts
    else
      opts ++ [into: ""]
    end
  end

  @spec command_inspect([String.t()]) :: String.t()
  defp command_inspect(command) when is_list(command), do: command |> Enum.join(" ")
end
