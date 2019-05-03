defmodule Mix.DeliPingTest do
  use DeliCase
  alias Mix.Tasks.Deli.Ping

  setup do
    put_config(:__system_handler__, SystemStub)
    put_config(:check, Deli.Check.Default)
  end

  property "pings application in all default target hosts by default" do
    check all app <- app(),
              app_user <- app_user(),
              env <- env(),
              hosts <- hosts(),
              pong? <- boolean(),
              verbose? <- boolean() do
      status = if pong?, do: "pong", else: "pang"
      put_config(:app, app)
      put_config(:app_user, [{env, app_user}])
      put_config(:default_target, env)
      put_config(:verbose, verbose?)
      stub_cmd({status, 0})

      stub(HostFilterMock, :hosts, fn ^env, _ -> {:ok, hosts} end)

      output =
        capture_io(fn ->
          :ok = Ping.run([])
        end)

      log =
        hosts
        |> Enum.map(fn host ->
          id = "#{app_user}@#{host}"

          if pong? do
            if verbose? do
              "\e[32mpong #{id}\e[0m\n#{status}\n"
            else
              "\e[32mpong #{id}\e[0m\n"
            end
          else
            "\e[31mnot pong #{id}\e[0m\n#{status}\n"
          end
        end)
        |> Enum.join("")

      assert output == log
    end
  end

  property "pings application in all target hosts by default" do
    check all app <- app(),
              app_user <- app_user(),
              env <- env(),
              hosts <- hosts(),
              pong? <- boolean(),
              short? <- boolean(),
              verbose? <- boolean() do
      flag = if short?, do: "-t", else: "--target"
      status = if pong?, do: "pong", else: "pang"
      put_config(:app, app)
      put_config(:app_user, [{env, app_user}])
      put_config(:verbose, verbose?)
      stub_cmd({status, 0})

      stub(HostFilterMock, :hosts, fn ^env, _ -> {:ok, hosts} end)

      output =
        capture_io(fn ->
          :ok = Ping.run([flag, env])
        end)

      log =
        hosts
        |> Enum.map(fn host ->
          id = "#{app_user}@#{host}"

          if pong? do
            if verbose? do
              "\e[32mpong #{id}\e[0m\n#{status}\n"
            else
              "\e[32mpong #{id}\e[0m\n"
            end
          else
            "\e[31mnot pong #{id}\e[0m\n#{status}\n"
          end
        end)
        |> Enum.join("")

      assert output == log
    end
  end
end
