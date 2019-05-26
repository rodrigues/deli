defmodule Deli.Controller.BinTest do
  use DeliCase, async: true
  alias Deli.Controller.Bin

  setup do
    put_config(:__system_handler__, SystemStub)
  end

  def nok_signal do
    2..500 |> integer() |> except(&(&1 == 127))
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
        id = Config.host_id(env, host)

        :ok = Bin.start_host(env, host)

        assert_receive {
          :__system_handler__,
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
                signal <- signal() do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"", signal})
        id = Config.host_id(env, host)

        call = fn ->
          capture_io(fn ->
            Bin.start_host(env, host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system_handler__,
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
        id = Config.host_id(env, host)

        :ok = Bin.stop_host(env, host)

        assert_receive {
          :__system_handler__,
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
                signal <- signal() do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"", signal})
        id = Config.host_id(env, host)

        call = fn ->
          capture_io(fn ->
            Bin.stop_host(env, host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system_handler__,
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
        id = Config.host_id(env, host)

        :ok = Bin.restart_host(env, host)

        assert_receive {
          :__system_handler__,
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
                signal <- signal() do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"", signal})
        id = Config.host_id(env, host)

        call = fn ->
          capture_io(fn ->
            Bin.restart_host(env, host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system_handler__,
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
                signal <- signal([0, 1, 127]) do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({status, signal})
        id = Config.host_id(env, host)

        ^status = Bin.service_status(env, host)

        assert_receive {
          :__system_handler__,
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
                signal <- nok_signal() do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"", signal})
        id = Config.host_id(env, host)

        call = fn ->
          capture_io(fn ->
            Bin.service_status(env, host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system_handler__,
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
                signal <- signal([0, 1, 127]) do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"pong", signal})
        id = Config.host_id(env, host)

        assert Bin.service_running?(env, host)

        assert_receive {
          :__system_handler__,
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
                signal <- signal([0, 1, 127]) do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"pang", signal})
        id = Config.host_id(env, host)

        refute Bin.service_running?(env, host)

        assert_receive {
          :__system_handler__,
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
                signal <- nok_signal() do
        put_config(:app_user, app_user)
        put_config(:bin_path, bin_path)
        stub_cmd({"", signal})
        id = Config.host_id(env, host)

        call = fn ->
          capture_io(fn ->
            Bin.service_running?(env, host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system_handler__,
          :cmd,
          "ssh",
          [^id, ^bin_path, "ping"],
          _
        }
      end
    end
  end
end
