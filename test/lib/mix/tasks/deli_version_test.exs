defmodule Mix.DeliVersionTest do
  use DeliCase
  alias Mix.Tasks.Deli.Version

  setup do
    put_config(:__system__, SystemStub)
  end

  def setup_versions(env, hosts) do
    length = hosts |> Enum.count()
    versions = version() |> Enum.take(length) |> Enum.map(&to_string/1)

    versions =
      hosts
      |> Enum.zip(versions)
      |> Enum.into(%{})

    HostProviderMock
    |> stub(:hosts, fn ^env -> hosts end)

    TestAgent.set(:cmd, fn _, [id | _], _ ->
      host = id |> String.split("@") |> List.last()
      result = "{:ok, '#{versions[host]}'}"
      {result, 0}
    end)

    versions
  end

  property "versions of application in all default target hosts by default" do
    check all app <- app(),
              app_user <- app_user(),
              bin_path <- bin_path(),
              env <- env(),
              hosts <- hosts() do
      put_config(:app, app)
      put_config(:app_user, [{env, app_user}])
      put_config(:bin_path, bin_path)
      put_config(:default_target, env)

      versions = env |> setup_versions(hosts)

      output =
        capture_io(fn ->
          :ok = Version.run([])
        end)

      host_output = fn f -> hosts |> Enum.map(f) |> Enum.join("") end
      hosts_output = host_output.(&"## #{&1}\n")
      versions_output = host_output.(&"\e[32m#{versions[&1]}\e[0m\n")

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

  property "versions of application in target env hosts" do
    check all app <- app(),
              app_user <- app_user(),
              bin_path <- bin_path(),
              env <- env(),
              hosts <- hosts(),
              short? <- boolean() do
      flag = if short?, do: "-t", else: "--target"
      versions = env |> setup_versions(hosts)

      put_config(:app, app)
      put_config(:app_user, [{env, app_user}])
      put_config(:bin_path, bin_path)

      opts = [flag, to_string(env)]

      output =
        capture_io(fn ->
          :ok = opts |> Version.run()
        end)

      host_output = fn f -> hosts |> Enum.map(f) |> Enum.join("") end
      hosts_output = host_output.(&"## #{&1}\n")
      versions_output = host_output.(&"\e[32m#{versions[&1]}\e[0m\n")

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

  property "versions of local environment when target is dev" do
    check all short? <- boolean() do
      flag = if short?, do: "-t", else: "--target"

      opts = [flag, "dev"]

      output =
        capture_io(fn ->
          :ok = opts |> Version.run()
        end)

      version = Deli.MixProject.project()[:version]
      assert output == "checking version of deli at dev environment\n\e[32m#{version}\e[0m\n"

      refute_received {
        :__system__,
        :cmd,
        "ssh",
        _,
        [into: ""]
      }
    end
  end

  property "compares versions of application in target env hosts" do
    check all app <- app(),
              app_user <- app_user(),
              bin_path <- bin_path(),
              env <- env(),
              hosts <- hosts(),
              short? <- boolean() do
      target_flag = if short?, do: "-t", else: "--target"
      compare_flag = if short?, do: "-c", else: "--compare"
      setup_versions(env, hosts)

      put_config(:app, app)
      put_config(:app_user, [{env, app_user}])
      put_config(:bin_path, bin_path)

      opts = [target_flag, to_string(env), compare_flag]

      output =
        capture_io(fn ->
          :ok = opts |> Version.run()
        end)

      host_output = fn f -> hosts |> Enum.map(f) |> Enum.join("") end
      hosts_output = host_output.(&"## #{&1}\n")

      hosts_involved = "# hosts\n#{hosts_output}"

      assert String.starts_with?(output, hosts_involved)

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
