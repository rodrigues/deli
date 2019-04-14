defmodule Mix.DeliStatusTest do
  use DeliCase
  alias Mix.Tasks.Deli.Status

  property "tells if application is running in all default target hosts by default" do
    check all app <- app(),
              app_user <- app_user(),
              env <- env(),
              hosts <- hosts(),
              verbose? <- boolean() do
      put_config(:app, app)
      put_config(:app_user, [{env, app_user}])
      put_config(:default_target, env)
      put_config(:verbose, verbose?)

      HostFilterMock
      |> stub(:hosts, fn ^env, _ -> {:ok, hosts} end)

      for host <- hosts do
        CheckMock
        |> expect(:run, fn ^env, ^host -> :ok end)
      end

      output =
        capture_io(fn ->
          :ok = Status.run([])
        end)

      assert output == ""
    end
  end

  property "tells if application is running in all target hosts" do
    check all app <- app(),
              app_user <- app_user(),
              env <- env(),
              hosts <- hosts(),
              short? <- boolean(),
              verbose? <- boolean() do
      flag = if short?, do: "-t", else: "--target"
      put_config(:app, app)
      put_config(:app_user, [{env, app_user}])
      put_config(:verbose, verbose?)

      HostFilterMock
      |> stub(:hosts, fn ^env, _ -> {:ok, hosts} end)

      for host <- hosts do
        CheckMock
        |> expect(:run, fn ^env, ^host -> :ok end)
      end

      output =
        capture_io(fn ->
          :ok = [flag, env] |> Status.run()
        end)

      assert output == ""
    end
  end
end
