defmodule Mix.DeliRestartTest do
  use DeliCase
  alias Mix.Tasks.Deli.Restart

  property "restarts application in all default target hosts by default" do
    check all app <- app(),
              app_user <- atom(),
              env <- atom(),
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
        |> expect(:service_running?, fn ^env, ^host -> true end)
        |> expect(:restart_host, fn ^env, ^host -> :ok end)
        |> expect(:service_running?, fn ^env, ^host -> true end)
      end

      output =
        capture_io(fn ->
          :ok = [flag] |> Restart.run()
        end)

      log =
        hosts
        |> Enum.map(fn host ->
          id = "#{app_user}@#{host}"

          "\e[32mrunning #{id}\e[0m\nrestarting #{id}...\n" <>
            "\e[32mrestarted #{id}\e[0m\n\e[32mrunning #{id}\e[0m\n"
        end)
        |> Enum.join("")

      assert output ==
               "# hosts\n## #{hosts |> Enum.join("\n## ")}\nrestart #{app} at #{env}? [Yn] y\n" <>
                 log
    end
  end

  property "restarts after confirmation when not passing yes" do
    check all env <- atom(),
              hosts <- hosts() do
      put_config(:default_target, env)

      HostProviderMock
      |> stub(:hosts, fn ^env -> hosts end)

      for host <- hosts do
        ControllerMock
        |> expect(:service_running?, fn ^env, ^host -> true end)
        |> expect(:restart_host, fn ^env, ^host -> :ok end)
        |> expect(:service_running?, fn ^env, ^host -> true end)
      end

      output =
        capture_io([input: "y\n", capture_prompt: true], fn ->
          :ok = Restart.run([])
        end)

      log =
        hosts
        |> Enum.map(fn host ->
          id = "deli@#{host}"

          "\e[32mrunning #{id}\e[0m\nrestarting #{id}...\n" <>
            "\e[32mrestarted #{id}\e[0m\n\e[32mrunning #{id}\e[0m\n"
        end)
        |> Enum.join("")

      assert output ==
               "# hosts\n## #{hosts |> Enum.join("\n## ")}\nrestart deli at #{env}? [Yn] " <>
                 log
    end
  end

  property "cancels after denial of confirmation when not passing yes" do
    check all env <- atom(),
              hosts <- hosts() do
      put_config(:default_target, env)

      HostProviderMock
      |> stub(:hosts, fn ^env -> hosts end)

      output =
        capture_io([input: "n\n", capture_prompt: true], fn ->
          :ok = Restart.run([])
        end)

      assert output ==
               "# hosts\n## #{hosts |> Enum.join("\n## ")}\nrestart deli at #{env}? [Yn] " <>
                 "\e[32mrestart cancelled by user\e[0m\n"
    end
  end
end
