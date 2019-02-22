defmodule Mix.DeliVersionTest do
  use DeliCase
  alias Mix.Tasks.Deli.Version

  setup do
    put_config(:__system__, SystemStub)
  end

  property "versions of application in all default target hosts by default" do
    check all app <- app(),
              app_user <- app_user(),
              bin_path <- bin_path(),
              env <- env(),
              hosts <- hosts() do
      length = hosts |> Enum.count()
      versions = version() |> Enum.take(length)

      versions =
        hosts
        |> Enum.zip(versions)
        |> Enum.into(%{})

      put_config(:app, app)
      put_config(:app_user, [{env, app_user}])
      put_config(:bin_path, bin_path)
      put_config(:default_target, env)

      HostProviderMock
      |> stub(:hosts, fn ^env -> hosts end)

      TestAgent.set(:cmd, fn _, [id | _], _ ->
        host = id |> String.split("@") |> List.last()
        {versions[host], 0}
      end)

      output =
        capture_io(fn ->
          :ok = Version.run([])
        end)

      host_output = fn f -> hosts |> Enum.map(f) |> Enum.join("") end
      hosts_output = host_output.(&"## #{&1}\n")
      versions_output = host_output.(&"\e[31m\"#{versions[&1]}\"\e[0m\n")

      assert output ==
               "# hosts\n#{hosts_output}checking version of #{app} at" <>
                 " target #{env}\n#{versions_output}"

      rpc_call = "\":application.get_key(:#{app}, :vsn)\""

      for host <- hosts do
        id = "#{app_user}@#{host}"

        assert_received {
          :__system__,
          :cmd,
          "ssh",
          [^id, ^bin_path, "rpc", ^rpc_call],
          [into: ""]
        }
      end
    end
  end
end
