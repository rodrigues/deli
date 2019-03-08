defmodule Mix.DeliStatusTest do
  use DeliCase
  alias Mix.Tasks.Deli.Status

  property "tells if application is running in all default target hosts by default" do
    check all app <- app(),
              app_user <- app_user(),
              env <- env(),
              hosts <- hosts(),
              status <- nonempty_string(),
              running? <- boolean(),
              verbose? <- boolean() do
      put_config(:app, app)
      put_config(:app_user, [{env, app_user}])
      put_config(:default_target, env)
      put_config(:verbose, verbose?)

      HostFilterMock
      |> stub(:hosts, fn ^env, _ -> {:ok, hosts} end)

      ControllerMock
      |> stub(:service_running?, fn ^env, _ -> running? end)
      |> stub(:service_status, fn ^env, _ -> status end)

      output =
        capture_io(fn ->
          :ok = Status.run([])
        end)

      log =
        hosts
        |> Enum.map(fn host ->
          id = "#{app_user}@#{host}"

          if running? do
            if verbose? do
              "\e[32mrunning #{id}\e[0m\n#{status}\n"
            else
              "\e[32mrunning #{id}\e[0m\n"
            end
          else
            "\e[31mnot running #{id}\e[0m\n#{status}\n"
          end
        end)
        |> Enum.join("")

      assert output == log
    end
  end

  property "tells if application is running in all target hosts" do
    check all app <- app(),
              app_user <- app_user(),
              env <- env(),
              hosts <- hosts(),
              status <- nonempty_string(),
              short? <- boolean(),
              running? <- boolean(),
              verbose? <- boolean() do
      flag = if short?, do: "-t", else: "--target"
      put_config(:app, app)
      put_config(:app_user, [{env, app_user}])
      put_config(:verbose, verbose?)

      HostFilterMock
      |> stub(:hosts, fn ^env, _ -> {:ok, hosts} end)

      ControllerMock
      |> stub(:service_running?, fn ^env, _ -> running? end)
      |> stub(:service_status, fn ^env, _ -> status end)

      output =
        capture_io(fn ->
          :ok = [flag, env] |> Status.run()
        end)

      log =
        hosts
        |> Enum.map(fn host ->
          id = "#{app_user}@#{host}"

          if running? do
            if verbose? do
              "\e[32mrunning #{id}\e[0m\n#{status}\n"
            else
              "\e[32mrunning #{id}\e[0m\n"
            end
          else
            "\e[31mnot running #{id}\e[0m\n#{status}\n"
          end
        end)
        |> Enum.join("")

      assert output == log
    end
  end
end
