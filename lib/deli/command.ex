defmodule Deli.Command do
  import Deli, only: [is_env: 1, is_host: 1]
  alias Deli.{Config, HostFilter, Shell}

  @moduledoc ~S"""
  Run commands locally or remotely.

  Defines a `behaviour` that application commands should implement.

  Provides conveniences to use these commands.

  ## Example

      # lib/mix/tasks/my_app/my_app.xyz.ex
      defmodule Mix.Tasks.MyApp.XYZ do
        use Mix.Task

        def run(args) do
          MyApp.Commands.XYZ |> Deli.Command.run(args)
        end
      end

      # lib/my_app/commands/my_command.ex
      defmodule MyApp.Commands.XYZ do
        @behaviour Deli.Command

        @impl true
        def run(args) do
          # do actual work
        end
      end

      # executes locally by default
      $ mix my_app.xyz --arg_example=1

      # runs command in all prod hosts
      $ mix my_app.xyz --arg_example=1 -t prod

      # runs command in all prod hosts that match ~r/01/
      $ mix my_app.xyz --arg_example=1 -t prod -h 01
  """

  @callback run(args :: OptionParser.argv()) :: :ok

  @doc ~S"""
  Either runs a command locally (dev), or through a RPC call
  to the remote target env
  """
  @spec call(Deli.env(), module, OptionParser.argv()) :: :ok
  def call(:dev, mod, args) when is_atom(mod) and is_list(args) do
    {:ok, _} = Config.app() |> Shell.ensure_all_started()
    :ok = mod |> apply(:run, [args])
    :ok
  end

  def call(env, mod, args) when is_env(env) and is_atom(mod) and is_list(args) do
    mod = mod |> to_string |> String.replace(~r/^Elixir\./, "")
    mfa = ~s("#{mod}.run/1")
    terms = args |> Enum.map(&to_string/1) |> Enum.join(" ")
    {:ok, hosts} = env |> HostFilter.hosts(args)
    hosts |> Enum.each(&call_host(env, &1, mfa, terms))
  end

  @doc ~S"""
  Fetches env from target (specified or default), and runs `call/3`
  """
  @spec run(module, OptionParser.argv()) :: :ok
  def run(command, args) when is_atom(command) and is_list(args) do
    args
    |> OptionParser.parse(aliases: [t: :target], switches: [target: :string])
    |> elem(0)
    |> Keyword.get(:target)
    |> Config.mix_env()
    |> call(command, args)
  end

  @spec call_host(Deli.env(), Deli.host(), String.t(), String.t()) :: :ok
  defp call_host(env, host, mfa, terms)
       when is_env(env) and is_host(host) and is_binary(mfa) and is_binary(terms) do
    cmd_args = [
      Config.host_id(env, host),
      Config.bin_path(),
      :eval,
      "--mfa",
      mfa,
      "--argv",
      "--",
      terms
    ]

    {:ok, result} = :ssh |> Shell.cmd_result(cmd_args)
    IO.puts(result)
  end
end
