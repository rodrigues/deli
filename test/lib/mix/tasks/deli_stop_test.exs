defmodule Mix.DeliStopTest do
  use DeliCase, async: true
  alias Mix.Tasks.Deli.Stop

  def setup_hosts(env, hosts, setup_mocks? \\ true) do
    stub(HostFilterMock, :hosts, fn ^env, _ -> {:ok, hosts} end)

    if setup_mocks? do
      for host <- hosts do
        CheckMock
        |> expect(:run, fn ^env, ^host -> :ok end)
        |> expect(:run, fn ^env, ^host, false -> :ok end)

        expect(ControllerMock, :stop_host, fn ^env, ^host -> :ok end)
      end
    end
  end

  property "stops application in all default target hosts by default" do
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
          :ok = Stop.run([flag])
        end)

      log =
        hosts
        |> Enum.map(fn host ->
          id = "#{app_user}@#{host}"
          "stopping #{id}...\n\e[32mstopped #{id}\e[0m\n"
        end)
        |> Enum.join("")

      assert output == "stop #{app} at #{env}? [Yn] y\n" <> log
    end
  end

  property "stops after confirmation when not passing yes" do
    check all env <- env(),
              hosts <- hosts() do
      put_config(:default_target, env)
      setup_hosts(env, hosts)

      output =
        capture_io([input: "y\n", capture_prompt: true], fn ->
          :ok = Stop.run([])
        end)

      log =
        hosts
        |> Enum.map(fn host ->
          id = "deli@#{host}"
          "stopping #{id}...\n\e[32mstopped #{id}\e[0m\n"
        end)
        |> Enum.join("")

      assert output == "stop deli at #{env}? [Yn] " <> log
    end
  end

  property "cancels after denial of confirmation when not passing yes" do
    check all env <- env(),
              hosts <- hosts() do
      put_config(:default_target, env)
      setup_hosts(env, hosts)

      output =
        capture_io([input: "n\n", capture_prompt: true], fn ->
          :ok = Stop.run([])
        end)

      assert output == "stop deli at #{env}? [Yn] \e[32mstop cancelled by user\e[0m\n"
    end
  end
end
