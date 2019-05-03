defmodule Mix.DeliRestartTest do
  use DeliCase
  alias Mix.Tasks.Deli.Restart

  def setup_hosts(env, hosts, setup_mocks? \\ true) do
    stub(HostFilterMock, :hosts, fn ^env, _ -> {:ok, hosts} end)

    if setup_mocks? do
      for host <- hosts do
        expect(CheckMock, :run, 2, fn ^env, ^host -> :ok end)
        expect(ControllerMock, :restart_host, fn ^env, ^host -> :ok end)
      end
    end
  end

  property "restarts application in all default target hosts by default" do
    check all app <- app(),
              app_user <- app_user(),
              env <- env(),
              hosts <- hosts(),
              short? <- boolean() do
      flag = if short?, do: "-y", else: "--yes"
      put_config(:app, app)
      put_config(:app_user, [{env, app_user}])
      put_config(:default_target, env)
      setup_hosts(env, hosts)

      output =
        capture_io(fn ->
          :ok = Restart.run([flag])
        end)

      log =
        hosts
        |> Enum.map(fn host ->
          id = "#{app_user}@#{host}"
          "restarting #{id}...\n\e[32mrestarted #{id}\e[0m\n"
        end)
        |> Enum.join("")

      assert output == "restart #{app} at #{env}? [Yn] y\n" <> log
    end
  end

  property "restarts after confirmation when not passing yes" do
    check all env <- env(),
              hosts <- hosts() do
      put_config(:default_target, env)
      setup_hosts(env, hosts)

      output =
        capture_io([input: "y\n", capture_prompt: true], fn ->
          :ok = Restart.run([])
        end)

      log =
        hosts
        |> Enum.map(fn host ->
          id = "deli@#{host}"

          "restarting #{id}...\n\e[32mrestarted #{id}\e[0m\n"
        end)
        |> Enum.join("")

      assert output == "restart deli at #{env}? [Yn] " <> log
    end
  end

  property "cancels after denial of confirmation when not passing yes" do
    check all env <- env(),
              hosts <- hosts() do
      put_config(:default_target, env)
      setup_hosts(env, hosts, false)

      output =
        capture_io([input: "n\n", capture_prompt: true], fn ->
          :ok = Restart.run([])
        end)

      assert output == "restart deli at #{env}? [Yn] \e[32mrestart cancelled by user\e[0m\n"
    end
  end
end
