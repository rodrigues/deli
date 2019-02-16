defmodule Mix.DeliStartTest do
  use DeliCase
  alias Mix.Tasks.Deli.Start

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

      HostProviderMock
      |> stub(:hosts, fn ^env -> hosts end)

      for host <- hosts do
        ControllerMock
        |> expect(:service_running?, fn ^env, ^host -> false end)
        |> expect(:start_host, fn ^env, ^host -> :ok end)
        |> expect(:service_running?, fn ^env, ^host -> true end)
      end

      output =
        capture_io(fn ->
          :ok = [flag] |> Start.run()
        end)

      log =
        hosts
        |> Enum.map(fn host ->
          id = "#{app_user}@#{host}"

          "\e[32mnot running #{id}\e[0m\nstarting #{id}...\n" <>
            "\e[32mstarted #{id}\e[0m\n\e[32mrunning #{id}\e[0m\n"
        end)
        |> Enum.join("")

      assert output ==
               "# hosts\n## #{hosts |> Enum.join("\n## ")}\nstart #{app} at #{env}? [Yn] y\n" <>
                 log
    end
  end

  property "starts after confirmation when not passing yes" do
    check all env <- env(),
              hosts <- hosts() do
      put_config(:default_target, env)

      HostProviderMock
      |> stub(:hosts, fn ^env -> hosts end)

      for host <- hosts do
        ControllerMock
        |> expect(:service_running?, fn ^env, ^host -> false end)
        |> expect(:start_host, fn ^env, ^host -> :ok end)
        |> expect(:service_running?, fn ^env, ^host -> true end)
      end

      output =
        capture_io([input: "y\n", capture_prompt: true], fn ->
          :ok = Start.run([])
        end)

      log =
        hosts
        |> Enum.map(fn host ->
          id = "deli@#{host}"

          "\e[32mnot running #{id}\e[0m\nstarting #{id}...\n" <>
            "\e[32mstarted #{id}\e[0m\n\e[32mrunning #{id}\e[0m\n"
        end)
        |> Enum.join("")

      assert output ==
               "# hosts\n## #{hosts |> Enum.join("\n## ")}\nstart deli at #{env}? [Yn] " <>
                 log
    end
  end

  property "cancels after denial of confirmation when not passing yes" do
    check all env <- env(),
              hosts <- hosts() do
      put_config(:default_target, env)

      HostProviderMock
      |> stub(:hosts, fn ^env -> hosts end)

      for host <- hosts do
        ControllerMock
        |> expect(:service_running?, fn ^env, ^host -> false end)
        |> expect(:start_host, fn ^env, ^host -> :ok end)
        |> expect(:service_running?, fn ^env, ^host -> true end)
      end

      output =
        capture_io([input: "n\n", capture_prompt: true], fn ->
          :ok = Start.run([])
        end)

      assert output ==
               "# hosts\n## #{hosts |> Enum.join("\n## ")}\nstart deli at #{env}? [Yn] " <>
                 "\e[32mstart cancelled by user\e[0m\n"
    end
  end
end
