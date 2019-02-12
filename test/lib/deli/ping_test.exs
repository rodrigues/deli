defmodule Deli.PingTest do
  use DeliCase
  alias Deli.Ping

  setup do
    put_config(:__system__, SystemStub)
  end

  describe "run/2" do
    property "pings host" do
      check all app <- atom() |> except(&is_nil/1),
                app_user <- atom() |> except(&is_nil/1),
                env <- atom() |> except(&is_nil/1),
                host <- non_empty_string() do
        put_config(:app, app)
        put_config(:app_user, app_user)
        stub_cmd({"pong", 0})

        output =
          capture_io(fn ->
            :ok = env |> Ping.run(host)
          end)

        id = "#{app_user}@#{host}"
        bin = "/opt/#{app}/bin/#{app}"

        assert_receive {
          :__system__,
          :cmd,
          "ssh",
          [^id, ^bin, "ping"],
          _
        }

        assert output == "\e[32mpong #{id}\e[0m\n"
      end
    end
  end
end
