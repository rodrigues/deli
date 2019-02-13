defmodule Deli.Controller.BinTest do
  use DeliCase
  alias Deli.Controller.Bin

  setup do
    put_config(:__system__, SystemStub)
  end

  describe "start_host/2" do
    property "starts host" do
      check all app_user <- atom() |> except(&is_nil/1),
                bin_path <- non_empty_string(),
                env <- atom() |> except(&is_nil/1),
                host <- non_empty_string() do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"", 0})
        id = env |> Config.host_id(host)

        :ok = env |> Bin.start_host(host)

        assert_receive {
          :__system__,
          :cmd,
          "ssh",
          [^id, ^bin_path, "start"],
          _
        }
      end
    end

    property "fails to start host if signal not expected" do
      check all app_user <- atom() |> except(&is_nil/1),
                bin_path <- non_empty_string(),
                env <- atom() |> except(&is_nil/1),
                host <- non_empty_string(),
                signal <- 1..500 |> integer() do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"", signal})
        id = env |> Config.host_id(host)

        call = fn ->
          capture_io(fn ->
            env |> Bin.start_host(host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system__,
          :cmd,
          "ssh",
          [^id, ^bin_path, "start"],
          _
        }
      end
    end
  end
end
