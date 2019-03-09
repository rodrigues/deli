defmodule Mix.DeliShellTest do
  use DeliCase
  alias Mix.Tasks.Deli.Shell

  setup do
    put_config(:waits, port_forwarding: 1)
    put_config(:__system_handler__, SystemStub)
  end

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
      epmd_path = "#{epmd_base_path}/epmd"
      put_config(:app, app)
      put_config(:cookie, cookie)
      put_config(:app_user, [{env, app_user}])
      put_config(:bin_path, bin_path)
      put_config(:default_target, env)

      HostFilterMock
      |> stub(:host, fn ^env, _ -> {:ok, host} end)

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
          send(TestAgent.get(:pid), :ssh_port_forwarded)
          {"", 0}

        "ps", ["aux"], _ ->
          {"", 0}

        "whoami", [], _ ->
          {whoami, 0}
      end)

      output =
        capture_io(fn ->
          :ok = Shell.run([])
        end)

      assert output ==
               "iex --name #{whoami}@127.0.0.1 --cookie #{cookie} " <>
                 "--remsh #{app}@127.0.0.1"
    end
  end
end
