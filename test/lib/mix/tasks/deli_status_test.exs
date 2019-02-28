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

      HostProviderMock
      |> stub(:hosts, fn ^env -> hosts end)

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

      assert output == "# hosts\n## #{hosts |> Enum.join("\n## ")}\n#{log}"
    end
  end
end
