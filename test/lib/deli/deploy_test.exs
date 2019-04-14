defmodule Deli.DeployTest do
  use DeliCase
  alias Deli.Deploy

  setup do
    put_config(:__system_handler__, SystemStub)
  end

  describe "run/2" do
    property "deploys application to host and restarts" do
      check all app <- app(),
                app_user <- app_user(),
                env <- env(),
                host <- host() do
        put_config(:app, app)
        put_config(:app_user, app_user)

        ControllerMock
        |> expect(:restart_host, fn ^env, ^host -> :ok end)

        CheckMock
        |> expect(:run, fn ^env, ^host -> :ok end)

        output =
          capture_io(fn ->
            :ok = env |> Deploy.run(host)
          end)

        cmd = "mix"
        args = ~w(edeliver deploy release to #{env} --host=#{host})
        assert_received {:__system_handler__, :cmd, ^cmd, ^args, _}

        id = "#{app_user}@#{host}"

        assert output == "restarting #{id}...\n\e[32mrestarted #{id}\e[0m\n"
      end
    end
  end
end
