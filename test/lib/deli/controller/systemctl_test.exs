defmodule Deli.Controller.SystemctlTest do
  use DeliCase, async: true
  alias Deli.Controller.Systemctl

  setup do
    put_config(:__system_handler__, SystemStub)
  end

  describe "start_host/2" do
    property "starts host" do
      check all app <- app(),
                env <- env(),
                host <- host() do
        put_config(:app, app)
        stub_cmd({"", 0})
        app = to_string(app)
        id = Config.host_id(env, host)

        :ok = Systemctl.start_host(env, host)

        assert_receive {
          :__system_handler__,
          :cmd,
          "ssh",
          [^id, "sudo", "systemctl", "start", ^app],
          _
        }
      end
    end

    property "fails to start host if signal not expected" do
      check all app <- app(),
                env <- env(),
                host <- host(),
                signal <- signal() do
        put_config(:app, app)
        stub_cmd({"", signal})
        app = to_string(app)
        id = Config.host_id(env, host)

        call = fn ->
          capture_io(fn ->
            Systemctl.start_host(env, host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system_handler__,
          :cmd,
          "ssh",
          [^id, "sudo", "systemctl", "start", ^app],
          _
        }
      end
    end
  end

  describe "stop_host/2" do
    property "stops host" do
      check all app <- app(),
                env <- env(),
                host <- host() do
        put_config(:app, app)
        stub_cmd({"", 0})
        app = to_string(app)
        id = Config.host_id(env, host)

        :ok = Systemctl.stop_host(env, host)

        assert_receive {
          :__system_handler__,
          :cmd,
          "ssh",
          [^id, "sudo", "systemctl", "stop", ^app],
          _
        }
      end
    end

    property "fails to stop host if signal not expected" do
      check all app <- app(),
                env <- env(),
                host <- host(),
                signal <- signal() do
        put_config(:app, app)
        stub_cmd({"", signal})
        app = to_string(app)
        id = Config.host_id(env, host)

        call = fn ->
          capture_io(fn ->
            Systemctl.stop_host(env, host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system_handler__,
          :cmd,
          "ssh",
          [^id, "sudo", "systemctl", "stop", ^app],
          _
        }
      end
    end
  end

  describe "restart_host/2" do
    property "restarts host" do
      check all app <- app(),
                env <- env(),
                host <- host() do
        put_config(:app, app)
        stub_cmd({"", 0})
        app = to_string(app)
        id = Config.host_id(env, host)

        :ok = Systemctl.restart_host(env, host)

        assert_receive {
          :__system_handler__,
          :cmd,
          "ssh",
          [^id, "sudo", "systemctl", "restart", ^app],
          _
        }
      end
    end

    property "fails to restart host if signal not expected" do
      check all app <- app(),
                env <- env(),
                host <- host(),
                signal <- signal() do
        put_config(:app, app)
        stub_cmd({"", signal})
        app = to_string(app)
        id = Config.host_id(env, host)

        call = fn ->
          capture_io(fn ->
            Systemctl.restart_host(env, host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system_handler__,
          :cmd,
          "ssh",
          [^id, "sudo", "systemctl", "restart", ^app],
          _
        }
      end
    end
  end

  describe "service_status/2" do
    property "returns status" do
      check all app <- app(),
                env <- env(),
                host <- host(),
                status <- string(),
                signal <- signal([0, 3]) do
        put_config(:app, app)
        stub_cmd({status, signal})
        app = to_string(app)
        id = Config.host_id(env, host)

        ^status = Systemctl.service_status(env, host)

        assert_receive {
          :__system_handler__,
          :cmd,
          "ssh",
          [^id, "", "systemctl", "status", ^app],
          _
        }
      end
    end

    # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
    property "fails to check status if signal not expected" do
      check all app <- app(),
                env <- env(),
                host <- host(),
                signal <- except(signal(), &(&1 == 3)) do
        put_config(:app, app)
        stub_cmd({"", signal})
        app = to_string(app)
        id = Config.host_id(env, host)

        call = fn ->
          capture_io(fn ->
            Systemctl.service_status(env, host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system_handler__,
          :cmd,
          "ssh",
          [^id, "", "systemctl", "status", ^app],
          _
        }
      end
    end
  end

  describe "service_running?/2" do
    property "true if status is good and signal ok" do
      check all app <- app(),
                env <- env(),
                host <- host(),
                signal <- signal([0, 3]) do
        put_config(:app, app)
        stub_cmd({"Active: active (running)", signal})
        app = to_string(app)
        id = Config.host_id(env, host)

        assert Systemctl.service_running?(env, host)

        assert_receive {
          :__system_handler__,
          :cmd,
          "ssh",
          [^id, "", "systemctl", "status", ^app],
          _
        }
      end
    end

    property "false if status not pong and signal ok" do
      check all app <- app(),
                env <- env(),
                host <- host(),
                signal <- signal([0, 3]) do
        put_config(:app, app)
        stub_cmd({"pang", signal})
        app = to_string(app)
        id = Config.host_id(env, host)

        refute Systemctl.service_running?(env, host)

        assert_receive {
          :__system_handler__,
          :cmd,
          "ssh",
          [^id, "", "systemctl", "status", ^app],
          _
        }
      end
    end

    property "fails to check status if signal not expected" do
      check all app <- app(),
                env <- env(),
                host <- host(),
                signal <- except(signal(), &(&1 == 3)) do
        put_config(:app, app)
        stub_cmd({"", signal})
        app = to_string(app)
        id = Config.host_id(env, host)

        call = fn ->
          capture_io(fn ->
            Systemctl.service_running?(env, host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system_handler__,
          :cmd,
          "ssh",
          [^id, "", "systemctl", "status", ^app],
          _
        }
      end
    end
  end
end
