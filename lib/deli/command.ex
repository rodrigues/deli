defmodule Deli.Command do
  import Deli.Shell
  alias Deli.Config

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
  """

  @callback run([String.t()]) :: :ok

  @doc ~S"""
  Either runs a command locally (dev), or through a RPC call
  to the remote target env
  """
  @spec call(
          env :: atom,
          module,
          args :: [String.t()]
        ) :: term
  def call(:dev, mod, args) do
    {:ok, _} = Config.app() |> Application.ensure_all_started()
    mod |> apply(:run, [args])
  end

  def call(env, mod, args) do
    mod = mod |> to_string |> String.replace(~r/^Elixir\./, "")
    mfa = ~s("#{mod}.run/1")
    terms = args |> Enum.map(&to_string/1) |> Enum.join(" ")
    env |> Config.hosts() |> Enum.each(&call_host(&1, mfa, terms))
  end

  @doc ~S"""
  Fetches env from target (specified or default), and runs `call/3`
  """
  @spec run(module, [String.t()]) :: :ok
  def run(command, args) do
    args
    |> OptionParser.parse(aliases: [t: :target], switches: [target: :string])
    |> elem(0)
    |> Keyword.get(:target)
    |> Config.mix_env()
    |> call(command, args)
  end

  defp call_host(host, mfa, terms) do
    app = Config.app()
    id = "#{app}@#{host}"

    cmd_args = [
      id,
      Config.bin_path(),
      :eval,
      "--mfa",
      mfa,
      "--argv",
      "--",
      terms
    ]

    {:ok, result} = :ssh |> cmd_result(cmd_args)
    IO.puts(result)
  end
end