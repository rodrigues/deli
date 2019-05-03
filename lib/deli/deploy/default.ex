defmodule Deli.Deploy.Default do
  import Deli, only: [is_env: 1, is_host: 1]
  import Deli.Shell, only: [edeliver: 2]
  alias Deli.Config

  @moduledoc false

  @behaviour Deli.Deploy

  @impl true
  def run(target, host) when is_env(target) and is_host(host) do
    edeliver_target = Config.edeliver_target(target)
    edeliver(:deploy, [:release, :to, edeliver_target, "--host=#{host}"])
    restart_host(target, host)
  end

  defp restart_host(env, host) when is_env(env) and is_host(host) do
    check = Config.check()
    controller = Config.controller()
    id = Config.host_id(env, host)

    IO.puts("restarting #{id}...")
    :ok = controller.restart_host(env, host)
    IO.puts([IO.ANSI.green(), "restarted #{id}", IO.ANSI.reset()])

    :timer.sleep(Config.wait(:started_check))
    check.run(env, host)
  end
end
