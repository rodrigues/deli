defmodule Mix.DeliVersionTest do
  use DeliCase
  alias Mix.Tasks.Deli.Version

  setup do
    put_config(:__system_handler__, SystemStub)
  end

  def setup_versions(env, hosts) do
    length = Enum.count(hosts)
    versions = version() |> Enum.take(length) |> Enum.map(&to_string/1)

    versions =
      hosts
      |> Enum.zip(versions)
      |> Enum.into(%{})

    stub(HostFilterMock, :hosts, fn ^env, _ -> {:ok, hosts} end)

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

      versions = setup_versions(env, hosts)

      output =
        capture_io(fn ->
          :ok = Version.run([])
        end)

      host_output = fn f -> hosts |> Enum.map(f) |> Enum.join("") end
      versions_output = host_output.(&"\e[32m#{versions[&1]}\e[0m\n")

      assert output ==
               "checking version of #{app} at" <>
                 " target #{env}\n#{versions_output}"

      rpc_call = "\":application.get_key(:#{app}, :vsn)\""

      for host <- hosts do
        id = "#{app_user}@#{host}"

        assert_received {
          :__system_handler__,
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
      versions = setup_versions(env, hosts)

      put_config(:app, app)
      put_config(:app_user, [{env, app_user}])
      put_config(:bin_path, bin_path)

      opts = [flag, to_string(env)]

      output =
        capture_io(fn ->
          :ok = Version.run(opts)
        end)

      host_output = fn f -> hosts |> Enum.map(f) |> Enum.join("") end
      versions_output = host_output.(&"\e[32m#{versions[&1]}\e[0m\n")

      assert output ==
               "checking version of #{app} at" <>
                 " target #{env}\n#{versions_output}"

      rpc_call = "\":application.get_key(:#{app}, :vsn)\""

      for host <- hosts do
        id = "#{app_user}@#{host}"

        assert_received {
          :__system_handler__,
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
          :ok = Version.run(opts)
        end)

      version = Deli.MixProject.project()[:version]
      assert output == "checking version of deli at dev environment\n\e[32m#{version}\e[0m\n"

      refute_received {
        :__system_handler__,
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

      capture_io(fn ->
        :ok = Version.run(opts)
      end)

      rpc_call = "\":application.get_key(:#{app}, :vsn)\""

      for host <- hosts do
        id = "#{app_user}@#{host}"

        assert_received {
          :__system_handler__,
          :cmd,
          "ssh",
          [^id, ^bin_path, "rpc", ^rpc_call],
          [into: ""]
        }
      end
    end
  end

  test "compare indicates when version is smaller" do
    env = pick(env())
    host = pick(host())

    stub(HostFilterMock, :hosts, fn ^env, _ -> {:ok, [host]} end)

    TestAgent.set(:cmd, fn _, _, _ ->
      {"{:ok, '0.0.1'}", 0}
    end)

    opts = ["-c", "-t", to_string(env)]

    output =
      capture_io(fn ->
        :ok = Version.run(opts)
      end)

    version = Deli.MixProject.project()[:version]

    assert output ==
             "\e[1m* #{host} \e[0m\e[31m\e[4moutdated\e[0m\e[1m  (0.0.1, local #{version})\e[0m\n"
  end

  test "compare indicates when version is bigger" do
    env = pick(env())
    host = pick(host())

    stub(HostFilterMock, :hosts, fn ^env, _ -> {:ok, [host]} end)

    TestAgent.set(:cmd, fn _, _, _ ->
      {"{:ok, '100.0.1'}", 0}
    end)

    opts = ["-c", "-t", to_string(env)]

    output =
      capture_io(fn ->
        :ok = Version.run(opts)
      end)

    version = Deli.MixProject.project()[:version]

    assert output ==
             "\e[1m* #{host} \e[0m\e[31m\e[4mahead\e[0m\e[1m  (100.0.1, local #{version})\e[0m\n"
  end

  test "compare indicates when version is equal" do
    env = pick(env())
    host = pick(host())
    version = Deli.MixProject.project()[:version]

    stub(HostFilterMock, :hosts, fn ^env, _ -> {:ok, [host]} end)

    TestAgent.set(:cmd, fn _, _, _ ->
      {"{:ok, '#{version}'}", 0}
    end)

    opts = ["-c", "-t", to_string(env)]

    output =
      capture_io(fn ->
        :ok = Version.run(opts)
      end)

    assert output ==
             "\e[1m* #{host} \e[0m\e[32mup-to-date\e[0m\e[2m  (#{version})\e[0m\n"
  end

  test "prints error when host version fails" do
    [app, app_user, bin_path, env, host] =
      Enum.map([app(), app_user(), bin_path(), env(), host()], &pick/1)

    hosts = [host]

    stub(HostFilterMock, :hosts, fn ^env, _ -> {:ok, hosts} end)

    TestAgent.set(:cmd, fn _, _, _ ->
      {"bad version", 0}
    end)

    put_config(:app, app)
    put_config(:app_user, [{env, app_user}])
    put_config(:bin_path, bin_path)

    opts = ["-t", to_string(env)]

    output =
      capture_io(fn ->
        :ok = Version.run(opts)
      end)

    assert output ==
             "checking version of #{app} at" <>
               " target #{env}\n\e[31m\"bad version\"\e[0m\n"

    rpc_call = "\":application.get_key(:#{app}, :vsn)\""

    for host <- hosts do
      id = "#{app_user}@#{host}"

      assert_received {
        :__system_handler__,
        :cmd,
        "ssh",
        [^id, ^bin_path, "rpc", ^rpc_call],
        [into: ""]
      }
    end
  end
end
