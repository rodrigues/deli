defmodule Mix.DeliStartTest do
  use DeliCase
  alias Mix.Tasks.Deli.Start

  def setup_hosts(env, hosts, setup_mocks? \\ true) do
    stub(HostFilterMock, :hosts, fn ^env, _ -> {:ok, hosts} end)

    if setup_mocks? do
      for host <- hosts do
        CheckMock
        |> expect(:run, fn ^env, ^host, false -> :ok end)
        |> expect(:run, fn ^env, ^host -> :ok end)

        expect(ControllerMock, :start_host, fn ^env, ^host -> :ok end)
      end
    end
  end

  property "starts application in all default target hosts by default" do
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
          :ok = Start.run([flag])
        end)

      log =
        hosts
        |> Enum.map(fn host ->
          id = "#{app_user}@#{host}"
          "starting #{id}...\n\e[32mstarted #{id}\e[0m\n"
        end)
        |> Enum.join("")

      assert output == "start #{app} at #{env}? [Yn] y\n" <> log
    end
  end

  property "starts after confirmation when not passing yes" do
    check all env <- env(),
              hosts <- hosts() do
      put_config(:default_target, env)
      setup_hosts(env, hosts)

      output =
        capture_io([input: "y\n", capture_prompt: true], fn ->
          :ok = Start.run([])
        end)

      log =
        hosts
        |> Enum.map(fn host ->
          id = "deli@#{host}"
          "starting #{id}...\n\e[32mstarted #{id}\e[0m\n"
        end)
        |> Enum.join("")

      assert output == "start deli at #{env}? [Yn] " <> log
    end
  end

  property "cancels after denial of confirmation when not passing yes" do
    check all env <- env(),
              hosts <- hosts() do
      put_config(:default_target, env)
      setup_hosts(env, hosts)

      output =
        capture_io([input: "n\n", capture_prompt: true], fn ->
          :ok = Start.run([])
        end)

      assert output == "start deli at #{env}? [Yn] \e[32mstart cancelled by user\e[0m\n"
    end
  end
end
