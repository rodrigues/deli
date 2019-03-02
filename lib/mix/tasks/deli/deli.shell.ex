defmodule Mix.Tasks.Deli.Shell do
  use Mix.Task
  import Deli.Shell
  alias Deli.{Config, HostFilter}

  @moduledoc """
  Returns the command you need to run to open a shell.

  In bash: `eval $(mix deli.shell)`.
  In fish: `eval (mix deli.shell)`.
  """

  @shortdoc "Provides shell command to run remote console"

  @impl true
  def run(args) do
    _ = Application.ensure_all_started(:deli)

    options = args |> parse_options
    extra_options = args |> parse_extra_options
    env = options |> Keyword.fetch!(:target)

    Application.put_env(:deli, :verbose, true)

    {:ok, host} = env |> HostFilter.host(args)

    spawn(fn -> port_forwarding(env, host) end)

    :timer.sleep(Config.wait(:port_forwarding))

    command =
      extra_options
      |> determine_shell
      |> command(env, host)

    print_command(command)

    :timer.sleep(Config.wait(:port_forwarding))
  end

  defp port_forwarding(env, host) do
    {epmd_port, app_port} = env |> fetch_ports(host)

    {:ok, processes} = :ps |> cmd_result([:aux])

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
      :ssh |> cmd(args, [0], into: "", parallelism: true)
    end
  end

  defp matching_ssh_command?(command, [_timeout | args]) do
    args = args |> Enum.join(" ")
    command |> String.contains?(args)
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
    IO.write(command |> Enum.join(" "))
  end

  defp whoami do
    'whoami' |> :os.cmd() |> to_string |> String.trim()
  end

  defp fetch_ports(env, host) do
    id = env |> Config.host_id(host)

    {:ok, erts_result} = :ssh |> cmd_result([id, "ps ax | grep epmd | grep erts"])

    epmd_path =
      erts_result
      |> String.split(" ", trim: true)
      |> Enum.find(&String.ends_with?(&1, "/epmd"))

    {:ok, epmd_names} = :ssh |> cmd_result([id, "#{epmd_path} -names"])

    lines = epmd_names |> String.split("\n")
    epmd = lines |> Enum.at(0) |> epmd_port
    app = lines |> Enum.find_value(&app_port/1)

    {epmd, app}
  end

  defp epmd_port(line) do
    [[_, port]] = ~r/port\s(\d+)/ |> Regex.scan(line)
    port
  end

  defp app_port(line) do
    app = Config.app()
    prefix = "name #{app} at port "

    if line |> String.starts_with?(prefix) do
      line |> String.replace_prefix(prefix, "")
    end
  end

  defp determine_shell(extra_options) do
    case extra_options |> Enum.at(0) do
      {shell, true} ->
        shell

      _ ->
        :remote
    end
  end

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
