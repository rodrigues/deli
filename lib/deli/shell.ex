defmodule Deli.Shell do
  alias Deli.Config

  @moduledoc false

  @type command :: atom | String.t()
  @type args :: [String.Chars.t()]
  @type exit_signal :: non_neg_integer
  @type ok_signals :: [exit_signal]

  @spec cmd(command, args, ok_signals, Keyword.t()) :: :ok
  def cmd(command, args \\ [], ok_signals \\ [0], opts \\ []) do
    {:ok, _} = do_cmd(command, args, ok_signals, opts)
    :ok
  end

  @spec cmd_result(command, args, ok_signals, Keyword.t()) ::
          {:ok, Collectable.t()}
  def cmd_result(command, args \\ [], ok_signals \\ [0], opts \\ []) do
    opts = [into: ""] ++ opts
    do_cmd(command, args, ok_signals, opts)
  end

  defp do_cmd(command, args, ok_signals, opts)
       when (is_atom(command) or is_binary(command)) and
              is_list(args) and is_list(ok_signals) and is_list(opts) do
    system = Config.__system_handler__()
    command = to_string(command)
    args = Enum.map(args, &to_string/1)
    verbose_inspect([command | args])

    {content, signal} = system.cmd(command, args, verbose_opts(opts))

    if Enum.member?(ok_signals, signal) do
      content =
        case content do
          %IO.Stream{} ->
            content

          _ ->
            to_string(content)
        end

      {:ok, content}
    else
      command_failed!(command, args, signal, content)
    end
  end

  @spec edeliver(command, args) :: :ok
  def edeliver(command, args \\ [])
      when (is_atom(command) or is_binary(command)) and is_list(args) do
    verbose = if Config.verbose?(), do: ["--verbose"], else: []
    edeliver_args = ["edeliver", command] ++ args ++ verbose
    cmd("mix", edeliver_args)
  end

  @spec docker_compose(command, args, ok_signals) :: :ok
  def docker_compose(command, args \\ [], ok_signals \\ [0]) do
    args = ["-f", ".deli/docker-compose.yml"] ++ [command] ++ args
    env = [{"COMPOSE_INTERACTIVE_NO_CLI", "1"}]
    cmd("docker-compose", args, ok_signals, env: env)
  end

  @spec file_exists?(Path.t()) :: boolean
  def file_exists?(path) do
    path |> expand_path |> file_handler().exists?()
  end

  @spec write_file(Path.t(), binary(), [mode :: atom]) :: :ok
  def write_file(path, content, options \\ []) do
    path |> expand_path |> file_handler().write!(content, options)
  end

  @spec expand_path(Path.t()) :: Path.t()
  def expand_path(path) do
    cwd = file_handler().cwd!()
    Path.expand(path, cwd)
  end

  @spec error!(String.t()) :: no_return
  def error!(message) do
    Mix.shell().error(message)
    exit({:shutdown, 1})
  end

  @spec confirm?(atom, Keyword.t()) :: boolean
  def confirm?(operation, options) when is_atom(operation) and is_list(options) do
    app = Config.app()
    target = Keyword.fetch!(options, :target)
    message = "#{operation} #{app} at #{target}?"

    if options[:yes] do
      IO.puts("#{message} [Yn] y")
      true
    else
      Mix.shell().yes?(message)
    end
  end

  @spec cancelled!(atom) :: :ok
  def cancelled!(operation) when is_atom(operation) do
    IO.puts([
      IO.ANSI.green(),
      to_string(operation),
      " cancelled by user",
      IO.ANSI.reset()
    ])
  end

  @spec parse_options(OptionParser.argv()) :: Keyword.t()
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

  @spec ensure_all_started(app :: atom) :: {:ok, [app :: atom]}
  def ensure_all_started(app) do
    Config.__application_handler__().ensure_all_started(app)
  end

  defp ensure_target(opts) do
    target = opts |> Keyword.get(:target, Config.default_target()) |> Config.mix_env()
    Keyword.put(opts, :target, target)
  end

  @spec command_failed!(command, args, exit_signal, Collectable.t()) :: no_return
  defp command_failed!(command, args, signal, content)
       when is_binary(command) and is_list(args) and is_integer(signal) do
    details = "(#{signal})"
    details = if content, do: "\n#{details} #{inspect(content)}", else: details

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

  defp verbose_opts(opts) do
    if Config.verbose?() do
      [into: IO.stream(:stdio, :line), stderr_to_stdout: true] ++ opts
    else
      Keyword.put_new(opts, :into, "")
    end
  end

  defp command_inspect(command) when is_list(command), do: Enum.join(command, " ")

  defp file_handler, do: Config.__file_handler__()
end
