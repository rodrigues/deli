defmodule Deli.Check.DefaultTest do
  use DeliCase, async: true
  alias Deli.Check.Default, as: Check

  test "behaviour" do
    assert behaves?(Check, Deli.Check)
  end

  describe "run/2" do
    def run(env, host, running_good? \\ true) do
      output =
        capture_io(fn ->
          :ok = Check.run(env, host, running_good?)
        end)

      id = Config.host_id(env, host)
      {id, output}
    end

    property "checks host and succeeds when service is running" do
      check all env <- env(),
                app_user <- app_user(),
                host <- host() do
        put_config(:app_user, app_user)

        expect(ControllerMock, :service_running?, fn ^env, ^host -> true end)
        {id, output} = run(env, host)
        assert output == "\e[32mrunning #{id}\e[0m\n"
      end
    end

    property "checks host and fails when service is not running" do
      check all env <- env(),
                app_user <- app_user(),
                host <- host(),
                status <- string() do
        put_config(:app_user, app_user)

        expect(ControllerMock, :service_running?, fn ^env, ^host -> false end)
        expect(ControllerMock, :service_status, fn ^env, ^host -> status end)
        {id, output} = run(env, host)
        assert output == "\e[31mnot running #{id}\e[0m\n#{status}\n"
      end
    end

    property "checks host and fails when service is running, " <>
               "but `running_good?` is false" do
      check all env <- env(),
                app_user <- app_user(),
                host <- host(),
                status <- string() do
        put_config(:app_user, app_user)

        ControllerMock
        |> expect(:service_running?, fn ^env, ^host -> true end)
        |> expect(:service_status, fn ^env, ^host -> status end)

        {id, output} = run(env, host, false)
        assert output == "\e[31mrunning #{id}\e[0m\n#{status}\n"
      end
    end

    property "checks host and succeeds when service is not running, " <>
               "but `running_good?` is false" do
      check all env <- env(),
                app_user <- app_user(),
                host <- host() do
        put_config(:app_user, app_user)

        expect(ControllerMock, :service_running?, fn ^env, ^host -> false end)
        {id, output} = run(env, host, false)
        assert output == "\e[32mnot running #{id}\e[0m\n"
      end
    end
  end
end
