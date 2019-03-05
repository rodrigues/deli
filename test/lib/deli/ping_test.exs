defmodule Deli.PingTest do
  use DeliCase
  alias Deli.Ping

  setup do
    put_config(:__system_handler__, SystemStub)
  end

  describe "run/2" do
    property "pings host and succeeds with a pong" do
      check all env <- env(),
                app_user <- app_user(),
                bin_path <- bin_path(),
                host <- host() do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"pong", 0})

        output =
          capture_io(fn ->
            :ok = env |> Ping.run(host)
          end)

        id = env |> Config.host_id(host)

        assert_receive {
          :__system_handler__,
          :cmd,
          "ssh",
          [^id, ^bin_path, "ping"],
          _
        }

        assert output == "\e[32mpong #{id}\e[0m\n"
      end
    end

    property "pings host and errors with not a pong" do
      check all env <- env(),
                app_user <- app_user(),
                bin_path <- bin_path(),
                host <- host(),
                response <- nonempty_string(),
                response != "pong" do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({response, 0})

        output =
          capture_io(fn ->
            :ok = env |> Ping.run(host)
          end)

        id = env |> Config.host_id(host)

        assert_receive {
          :__system_handler__,
          :cmd,
          "ssh",
          [^id, ^bin_path, "ping"],
          _
        }

        assert output == "\e[31mnot pong #{id}\e[0m\n#{response}\n"
      end
    end
  end
end
