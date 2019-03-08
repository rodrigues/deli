defmodule Deli.CommandTest do
  use DeliCase
  alias Deli.Command

  setup do
    put_config(:__system_handler__, SystemStub)
  end

  defmodule CommandExample do
    @behaviour Command

    def run(args) do
      send(TestAgent.get(:pid), {:command_example_call, args})
      IO.puts("COMMAND_EXAMPLE_RESULT")
      :ok
    end
  end

  describe "run/2" do
    property "runs command in all target env hosts when target specified" do
      check all app <- app(),
                bin_path <- bin_path(),
                env <- env() |> except(&(&1 == :dev)),
                hosts <- hosts(),
                args <- cmd_args(),
                result <- string(),
                short? <- boolean(),
                flag = if(short?, do: "-t", else: "--target"),
                not Enum.member?(args, flag) do
        args = ["-t", env | args]
        put_config(:app, app)
        put_config(:bin_path, bin_path)
        app = app |> to_string

        terms = [
          "eval",
          "--mfa",
          "\"Deli.CommandTest.CommandExample.run/1\"",
          "--argv",
          "--",
          Enum.join(args, " ")
        ]

        TestAgent.set(:cmd, fn
          "ssh", [id, ^bin_path | ^terms], into: "" ->
            with [^app, host] <- id |> String.split("@"),
                 true <- hosts |> Enum.member?(host) do
              {result, 0}
            else
              _ ->
                {"", 1}
            end

          _, _, _ ->
            {"", 1}
        end)

        HostFilterMock
        |> expect(:hosts, fn ^env, ^args -> {:ok, hosts} end)

        output =
          capture_io(fn ->
            :ok = CommandExample |> Command.run(args)
          end)

        results = hosts |> Enum.map(fn _ -> "#{result}\n" end) |> Enum.join("")
        assert output == results

        refute_received {:command_example_call, _}
      end
    end

    property "runs command locally when target not specified or when specified dev" do
      check all app <- app(),
                bin_path <- bin_path(),
                hosts <- hosts(),
                args <- cmd_args(),
                specify_target? <- boolean(),
                short? <- boolean(),
                default_target <- env(),
                flag = if(short?, do: "-t", else: "--target"),
                not Enum.member?(args, flag) do
        env = :dev
        put_config(:__application_handler__, ApplicationStub)
        put_config(:app, app)
        put_config(:bin_path, bin_path)
        put_config(:default_target, default_target)

        args = if specify_target?, do: ["-t", "dev" | args], else: args

        TestAgent.set(:ensure_all_started, fn ^app -> {:ok, [app]} end)

        HostFilterMock
        |> expect(:hosts, fn ^env, ^args -> {:ok, hosts} end)

        output =
          capture_io(fn ->
            :ok = CommandExample |> Command.run(args)
          end)

        assert output == "COMMAND_EXAMPLE_RESULT\n"

        assert_received {:command_example_call, ^args}
        refute_received {:__system_handler__, :cmd, _, _, _}
      end
    end
  end
end
