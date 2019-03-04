defmodule Deli.Controller.BinTest do
  use DeliCase
  alias Deli.Controller.Bin

  setup do
    put_config(:__system__, SystemStub)
  end

  describe "start_host/2" do
    property "starts host" do
      check all app_user <- app_user(),
                bin_path <- bin_path(),
                env <- env(),
                host <- host() do
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
      check all app_user <- app_user(),
                bin_path <- bin_path(),
                env <- env(),
                host <- host(),
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

  describe "stop_host/2" do
    property "stops host" do
      check all app_user <- app_user(),
                bin_path <- bin_path(),
                env <- env(),
                host <- host() do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"", 0})
        id = env |> Config.host_id(host)

        :ok = env |> Bin.stop_host(host)

        assert_receive {
          :__system__,
          :cmd,
          "ssh",
          [^id, ^bin_path, "stop"],
          _
        }
      end
    end

    property "fails to stop host if signal not expected" do
      check all app_user <- app_user(),
                bin_path <- bin_path(),
                env <- env(),
                host <- host(),
                signal <- 1..500 |> integer() do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"", signal})
        id = env |> Config.host_id(host)

        call = fn ->
          capture_io(fn ->
            env |> Bin.stop_host(host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system__,
          :cmd,
          "ssh",
          [^id, ^bin_path, "stop"],
          _
        }
      end
    end
  end

  describe "restart_host/2" do
    property "restarts host" do
      check all app_user <- app_user(),
                bin_path <- bin_path(),
                env <- env(),
                host <- host() do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"", 0})
        id = env |> Config.host_id(host)

        :ok = env |> Bin.restart_host(host)

        assert_receive {
          :__system__,
          :cmd,
          "ssh",
          [^id, ^bin_path, "restart"],
          _
        }
      end
    end

    property "fails to restart host if signal not expected" do
      check all app_user <- app_user(),
                bin_path <- bin_path(),
                env <- env(),
                host <- host(),
                signal <- 1..500 |> integer() do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"", signal})
        id = env |> Config.host_id(host)

        call = fn ->
          capture_io(fn ->
            env |> Bin.restart_host(host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system__,
          :cmd,
          "ssh",
          [^id, ^bin_path, "restart"],
          _
        }
      end
    end
  end

  describe "service_status/2" do
    property "returns status" do
      check all app_user <- app_user(),
                bin_path <- bin_path(),
                env <- env(),
                host <- host(),
                status <- string(),
                [signal] = [0, 1, 127] |> Enum.take_random(1) do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({status, signal})
        id = env |> Config.host_id(host)

        ^status = env |> Bin.service_status(host)

        assert_receive {
          :__system__,
          :cmd,
          "ssh",
          [^id, ^bin_path, "ping"],
          _
        }
      end
    end

    property "fails to check status if signal not expected" do
      check all app_user <- app_user(),
                bin_path <- bin_path(),
                env <- env(),
                host <- host(),
                signal <- 2..500 |> integer() |> except(&(&1 == 127)) do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"", signal})
        id = env |> Config.host_id(host)

        call = fn ->
          capture_io(fn ->
            env |> Bin.service_status(host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system__,
          :cmd,
          "ssh",
          [^id, ^bin_path, "ping"],
          _
        }
      end
    end
  end

  describe "service_running?/2" do
    property "true if status is pong and signal ok" do
      check all app_user <- app_user(),
                bin_path <- bin_path(),
                env <- env(),
                host <- host(),
                [signal] = [0, 1, 127] |> Enum.take_random(1) do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"pong", signal})
        id = env |> Config.host_id(host)

        assert Bin.service_running?(env, host)

        assert_receive {
          :__system__,
          :cmd,
          "ssh",
          [^id, ^bin_path, "ping"],
          _
        }
      end
    end

    property "false if status not pong and signal ok" do
      check all app_user <- app_user(),
                bin_path <- bin_path(),
                env <- env(),
                host <- host(),
                [signal] = [0, 1, 127] |> Enum.take_random(1) do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"pang", signal})
        id = env |> Config.host_id(host)

        refute Bin.service_running?(env, host)

        assert_receive {
          :__system__,
          :cmd,
          "ssh",
          [^id, ^bin_path, "ping"],
          _
        }
      end
    end

    property "fails to check status if signal not expected" do
      check all app_user <- app_user(),
                bin_path <- bin_path(),
                env <- env(),
                host <- host(),
                signal <- 2..500 |> integer() |> except(&(&1 == 127)) do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"", signal})
        id = env |> Config.host_id(host)

        call = fn ->
          capture_io(fn ->
            env |> Bin.service_running?(host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system__,
          :cmd,
          "ssh",
          [^id, ^bin_path, "ping"],
          _
        }
      end
    end
  end
end
