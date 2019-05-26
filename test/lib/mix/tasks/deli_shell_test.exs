defmodule Mix.DeliShellTest do
  use DeliCase, async: false
  alias Mix.Tasks.Deli.Shell

  setup do
    put_config(:waits, :port_forwarding, 1)
    put_config(:__system_handler__, SystemStub)
  end

  def setup_shell_test(%{
        app: app,
        app_user: app_user,
        cookie: cookie,
        bin_path: bin_path,
        epmd_base_path: epmd_base_path,
        epmd_port: epmd_port,
        app_port: app_port,
        env: env,
        host: host,
        whoami: whoami,
        pid: pid
      }) do
    epmd_path = "#{epmd_base_path}/epmd"
    put_config(:app, app)
    put_config(:cookie, cookie)
    put_config(:app_user, [{env, app_user}])
    put_config(:bin_path, bin_path)
    put_config(:default_target, env)

    stub(HostFilterMock, :host, fn ^env, _ -> {:ok, host} end)

    id = "#{app_user}@#{host}"

    epmd_fwd = "-L#{epmd_port}:localhost:#{epmd_port}"
    app_fwd = "-L#{app_port}:localhost:#{app_port}"
    epmd_names_call = "#{epmd_path} -names"

    TestAgent.set(:cmd, fn
      "ssh", [^id, "ps ax | grep epmd | grep erts"], _ ->
        {epmd_path, 0}

      "ssh", [^id, ^epmd_names_call], _ ->
        {"port #{epmd_port}\nname #{app} at port #{app_port}", 0}

      "ssh", [^id, ^epmd_fwd, ^app_fwd], _ ->
        send(pid, :ssh_port_forwarded)
        {"", 0}

      "ps", ["aux"], _ ->
        {"proc1nono\nproc2nono\n", 0}

      "whoami", [], _ ->
        {whoami, 0}
    end)
  end

  @moduletag :wip
  property "outputs shell command to connect to target remote node by default" do
    check all app <- app(),
              app_user <- app_user(),
              cookie <- strict_atom(),
              bin_path <- bin_path(),
              epmd_base_path <- path(),
              epmd_port <- port(),
              app_port <- port(),
              env <- env(),
              host <- host(),
              whoami <- nonempty_string() do
      setup_shell_test(%{
        app: app,
        app_user: app_user,
        cookie: cookie,
        bin_path: bin_path,
        epmd_base_path: epmd_base_path,
        epmd_port: epmd_port,
        app_port: app_port,
        env: env,
        host: host,
        whoami: whoami,
        pid: self()
      })

      output =
        capture_io(fn ->
          :ok = Shell.run([])
        end)

      assert output ==
               "iex --name #{whoami}@127.0.0.1 --cookie #{cookie} " <>
                 "--remsh #{app}@127.0.0.1"

      assert_received :ssh_port_forwarded
    end
  end

  property "outputs shell command to connect to target remote node when -r" do
    check all app <- app(),
              app_user <- app_user(),
              cookie <- strict_atom(),
              bin_path <- bin_path(),
              epmd_base_path <- path(),
              epmd_port <- port(),
              app_port <- port(),
              env <- env(),
              host <- host(),
              whoami <- nonempty_string(),
              short? <- boolean() do
      flag = if short?, do: "-r", else: "--remote"

      setup_shell_test(%{
        app: app,
        app_user: app_user,
        cookie: cookie,
        bin_path: bin_path,
        epmd_base_path: epmd_base_path,
        epmd_port: epmd_port,
        app_port: app_port,
        env: env,
        host: host,
        whoami: whoami,
        pid: self()
      })

      output =
        capture_io(fn ->
          :ok = Shell.run([flag])
        end)

      assert output ==
               "iex --name #{whoami}@127.0.0.1 --cookie #{cookie} " <>
                 "--remsh #{app}@127.0.0.1"

      assert_received :ssh_port_forwarded
    end
  end

  property "outputs shell command to observe remote node when -o" do
    check all app <- app(),
              app_user <- app_user(),
              cookie <- strict_atom(),
              bin_path <- bin_path(),
              epmd_base_path <- path(),
              epmd_port <- port(),
              app_port <- port(),
              env <- env(),
              host <- host(),
              whoami <- nonempty_string(),
              short? <- boolean() do
      flag = if short?, do: "-o", else: "--observer"

      setup_shell_test(%{
        app: app,
        app_user: app_user,
        cookie: cookie,
        bin_path: bin_path,
        epmd_base_path: epmd_base_path,
        epmd_port: epmd_port,
        app_port: app_port,
        env: env,
        host: host,
        whoami: whoami,
        pid: self()
      })

      output =
        capture_io(fn ->
          :ok = Shell.run([flag])
        end)

      assert output ==
               "iex --name #{whoami}@127.0.0.1 --cookie #{cookie} " <>
                 "-e 'Node.connect(:\"#{app}@127.0.0.1\"); :observer.start()'"

      assert_received :ssh_port_forwarded
    end
  end

  property "outputs shell command to connect to bin remote_console when -b" do
    check all app <- app(),
              app_user <- app_user(),
              cookie <- strict_atom(),
              bin_path <- bin_path(),
              epmd_base_path <- path(),
              epmd_port <- port(),
              app_port <- port(),
              env <- env(),
              host <- host(),
              whoami <- nonempty_string(),
              short? <- boolean() do
      flag = if short?, do: "-b", else: "--bin"

      setup_shell_test(%{
        app: app,
        app_user: app_user,
        cookie: cookie,
        bin_path: bin_path,
        epmd_base_path: epmd_base_path,
        epmd_port: epmd_port,
        app_port: app_port,
        env: env,
        host: host,
        whoami: whoami,
        pid: self()
      })

      output =
        capture_io(fn ->
          :ok = Shell.run([flag])
        end)

      assert output == "ssh #{app_user}@#{host} #{bin_path} remote_console"
      assert_received :ssh_port_forwarded
    end
  end
end
