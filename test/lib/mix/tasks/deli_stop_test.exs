defmodule Mix.DeliStopTest do
  use DeliCase
  alias Mix.Tasks.Deli.Stop

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

      HostFilterMock
      |> stub(:hosts, fn ^env, _ -> {:ok, hosts} end)

      for host <- hosts do
        ControllerMock
        |> expect(:service_running?, fn ^env, ^host -> true end)
        |> expect(:stop_host, fn ^env, ^host -> :ok end)
        |> expect(:service_running?, fn ^env, ^host -> false end)
      end

      output =
        capture_io(fn ->
          :ok = [flag] |> Stop.run()
        end)

      log =
        hosts
        |> Enum.map(fn host ->
          id = "#{app_user}@#{host}"

          "\e[32mrunning #{id}\e[0m\nstopping #{id}...\n" <>
            "\e[32mstopped #{id}\e[0m\n\e[32mnot running #{id}\e[0m\n"
        end)
        |> Enum.join("")

      assert output == "stop #{app} at #{env}? [Yn] y\n" <> log
    end
  end

  property "stops after confirmation when not passing yes" do
    check all env <- env(),
              hosts <- hosts() do
      put_config(:default_target, env)

      HostFilterMock
      |> stub(:hosts, fn ^env, _ -> {:ok, hosts} end)

      for host <- hosts do
        ControllerMock
        |> expect(:service_running?, fn ^env, ^host -> true end)
        |> expect(:stop_host, fn ^env, ^host -> :ok end)
        |> expect(:service_running?, fn ^env, ^host -> false end)
      end

      output =
        capture_io([input: "y\n", capture_prompt: true], fn ->
          :ok = Stop.run([])
        end)

      log =
        hosts
        |> Enum.map(fn host ->
          id = "deli@#{host}"

          "\e[32mrunning #{id}\e[0m\nstopping #{id}...\n" <>
            "\e[32mstopped #{id}\e[0m\n\e[32mnot running #{id}\e[0m\n"
        end)
        |> Enum.join("")

      assert output == "stop deli at #{env}? [Yn] " <> log
    end
  end

  property "cancels after denial of confirmation when not passing yes" do
    check all env <- env(),
              hosts <- hosts() do
      put_config(:default_target, env)

      HostFilterMock
      |> stub(:hosts, fn ^env, _ -> {:ok, hosts} end)

      for host <- hosts do
        ControllerMock
        |> expect(:service_running?, fn ^env, ^host -> true end)
        |> expect(:stop_host, fn ^env, ^host -> :ok end)
        |> expect(:service_running?, fn ^env, ^host -> false end)
      end

      output =
        capture_io([input: "n\n", capture_prompt: true], fn ->
          :ok = Stop.run([])
        end)

      assert output == "stop deli at #{env}? [Yn] \e[32mstop cancelled by user\e[0m\n"
    end
  end
end
