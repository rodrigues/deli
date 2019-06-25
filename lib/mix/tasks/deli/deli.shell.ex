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

  @impl true
  def run(args) do
    _ = ensure_all_started(:deli)

    options = parse_options(args)
    extra_options = parse_extra_options(args)
    env = Keyword.fetch!(options, :target)

    Application.put_env(:deli, :verbose, true)

    {:ok, host} = Config.host_filter().host(env, args)

    :proc_lib.spawn(__MODULE__, :port_forwarding, [env, host])

    :timer.sleep(Config.wait(:port_forwarding))

    command =
      extra_options
      |> determine_shell
      |> command(env, host)

    print_command(command)

    :timer.sleep(Config.wait(:port_forwarding))
  end

  def port_forwarding(env, host) do
    {epmd_port, app_port} = fetch_ports(env, host)

    {:ok, processes} = cmd_result(:ps, [:aux])

    args = [
      Config.host_id(env, host),
      "-L#{epmd_port}:localhost:#{epmd_port}",
      "-L#{app_port}:localhost:#{app_port}"
    ]

    running? =
      processes
      |> String.split("\n", trim: true)
      |> Enum.any?(&matching_ssh_command?(&1, args))

    unless running? do
      cmd(:ssh, args, [0], into: "", parallelism: true)
    end
  end

  defp matching_ssh_command?(command, [_timeout | args]) do
    args = Enum.join(args, " ")
    String.contains?(command, args)
  end

  defp command(:remote, _env, _host) do
    app = Config.app()
    cookie = Config.cookie()

    [
      "iex",
      "--name #{whoami()}@127.0.0.1",
      "--cookie #{cookie}",
      "--remsh #{app}@127.0.0.1"
    ]
  end

  defp command(:observer, _env, _host) do
    app = Config.app()
    cookie = Config.cookie()

    [
      "iex",
      "--name #{whoami()}@127.0.0.1",
      "--cookie #{cookie}",
      "-e 'Node.connect(:\"#{app}@127.0.0.1\"); :observer.start()'"
    ]
  end

  defp command(:bin, env, host) do
    [
      "ssh",
      Config.host_id(env, host),
      Config.bin_path(),
      "remote_console"
    ]
  end

  defp print_command(command) do
    command |> Enum.join(" ") |> IO.write()
  end

  defp whoami do
    {:ok, result} = cmd_result(:whoami, [])
    String.trim(result)
  end

  defp fetch_ports(env, host) do
    id = Config.host_id(env, host)

    {:ok, erts_result} = cmd_result(:ssh, [id, "ps ax | grep epmd | grep erts"])

    epmd_path =
      erts_result
      |> String.split(" ", trim: true)
      |> Enum.find(&String.ends_with?(&1, "/epmd"))

    {:ok, epmd_names} = cmd_result(:ssh, [id, "#{epmd_path} -names"])

    [epmd_line | app_lines] = String.split(epmd_names, "\n")
    epmd = epmd_port(epmd_line)
    app = Enum.find_value(app_lines, &app_port/1)

    {epmd, app}
  end

  defp epmd_port(line) do
    [[_, port]] = Regex.scan(~r/port\s(\d+)/, line)
    port
  end

  defp app_port(line) do
    app = Config.app()
    prefix = "name #{app} at port "

    if String.starts_with?(line, prefix) do
      String.replace_prefix(line, prefix, "")
    end
  end

  defp determine_shell([{shell, true} | _]) when is_atom(shell), do: shell
  defp determine_shell(_), do: :remote

  defp parse_extra_options(args) do
    options = [
      observer: :boolean,
      bin: :boolean,
      remote: :boolean
    ]

    aliases = [
      o: :observer,
      b: :bin,
      r: :remote
    ]

    args
    |> OptionParser.parse(aliases: aliases, switches: options)
    |> elem(0)
  end
end
