defmodule Deli.Deploy do
  import Deli, only: [is_env: 1, is_host: 1]
  import Deli.Shell, only: [edeliver: 2]
  alias Deli.Config

  @moduledoc false

  @spec run(Deli.env(), Deli.host()) :: :ok
  def run(target, host) when is_env(target) and is_host(host) do
    edeliver_target = target |> Config.edeliver_target()
    edeliver(:deploy, [:release, :to, edeliver_target, "--host=#{host}"])
    restart_host(target, host)
  end

  defp restart_host(env, host) when is_env(env) and is_host(host) do
    check = Config.check()
    controller = Config.controller()
    id = env |> Config.host_id(host)

    IO.puts("restarting #{id}...")
    :ok = env |> controller.restart_host(host)
    IO.puts([IO.ANSI.green(), "restarted #{id}", IO.ANSI.reset()])

    :timer.sleep(Config.wait(:started_check))
    check.run(env, host)
  end
end
