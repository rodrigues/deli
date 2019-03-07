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
      :ok
    end
  end

  describe "run/2" do
    property "runs command in all default target env hosts if target not specified" do
      check all app <- app(),
                bin_path <- bin_path(),
                env <- env() |> except(&(&1 == :dev)),
                hosts <- hosts(),
                args <- cmd_args(),
                result <- string() do
        put_config(:app, app)
        put_config(:bin_path, bin_path)
        put_config(:default_target, env)
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

        HostProviderMock
        |> expect(:hosts, fn ^env -> hosts end)

        output =
          capture_io(fn ->
            :ok = CommandExample |> Command.run(args)
          end)

        results = hosts |> Enum.map(fn _ -> "#{result}\n" end)
        assert output == "# hosts\n## #{hosts |> Enum.join("\n## ")}\n#{results}"

        refute_received {:command_example_call, _}
      end
    end
  end
end
