defmodule Deli.Controller.SystemctlTest do
  use DeliCase
  alias Deli.Controller.Systemctl

  setup do
    put_config(:__system__, SystemStub)
  end

  describe "start_host/2" do
    property "starts host" do
      check all app <- app(),
                env <- env(),
                host <- host() do
        put_config(:app, app)
        stub_cmd({"", 0})
        app = app |> to_string
        id = env |> Config.host_id(host)

        :ok = env |> Systemctl.start_host(host)

        assert_receive {
          :__system__,
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
                signal <- 1..500 |> integer() do
        put_config(:app, app)
        stub_cmd({"", signal})
        app = app |> to_string
        id = env |> Config.host_id(host)

        call = fn ->
          capture_io(fn ->
            env |> Systemctl.start_host(host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system__,
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
        app = app |> to_string
        id = env |> Config.host_id(host)

        :ok = env |> Systemctl.stop_host(host)

        assert_receive {
          :__system__,
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
                signal <- 1..500 |> integer() do
        put_config(:app, app)
        stub_cmd({"", signal})
        app = app |> to_string
        id = env |> Config.host_id(host)

        call = fn ->
          capture_io(fn ->
            env |> Systemctl.stop_host(host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system__,
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
        app = app |> to_string
        id = env |> Config.host_id(host)

        :ok = env |> Systemctl.restart_host(host)

        assert_receive {
          :__system__,
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
                signal <- 1..500 |> integer() do
        put_config(:app, app)
        stub_cmd({"", signal})
        app = app |> to_string
        id = env |> Config.host_id(host)

        call = fn ->
          capture_io(fn ->
            env |> Systemctl.restart_host(host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system__,
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
                [signal] = [0, 3] |> Enum.take_random(1) do
        put_config(:app, app)
        stub_cmd({status, signal})
        app = app |> to_string
        id = env |> Config.host_id(host)

        ^status = env |> Systemctl.service_status(host)

        assert_receive {
          :__system__,
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
                signal <- 2..500 |> integer() |> except(&(&1 == 127)) do
        put_config(:app, app)
        stub_cmd({"", signal})
        app = app |> to_string
        id = env |> Config.host_id(host)

        call = fn ->
          capture_io(fn ->
            env |> Systemctl.service_status(host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system__,
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
                [signal] = [0, 3] |> Enum.take_random(1) do
        put_config(:app, app)
        stub_cmd({"Active: active (running)", signal})
        app = app |> to_string
        id = env |> Config.host_id(host)

        assert Systemctl.service_running?(env, host)

        assert_receive {
          :__system__,
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
                [signal] = [0, 3] |> Enum.take_random(1) do
        put_config(:app, app)
        stub_cmd({"pang", signal})
        app = app |> to_string
        id = env |> Config.host_id(host)

        refute Systemctl.service_running?(env, host)

        assert_receive {
          :__system__,
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
                signal <- 1..500 |> integer() |> except(&(&1 == 3)) do
        put_config(:app, app)
        stub_cmd({"", signal})
        app = app |> to_string
        id = env |> Config.host_id(host)

        call = fn ->
          capture_io(fn ->
            env |> Systemctl.service_running?(host)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}

        assert_receive {
          :__system__,
          :cmd,
          "ssh",
          [^id, "", "systemctl", "status", ^app],
          _
        }
      end
    end
  end
end
