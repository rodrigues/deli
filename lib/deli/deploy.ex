defmodule Deli.Deploy do
  import Deli.Shell
  alias Deli.Config

  @moduledoc false

  def run(target) do
    IO.puts("🤞")
    edeliver_target = target |> Config.edeliver_target()
    edeliver("deploy release to #{edeliver_target}")
    restart_target(target)
    edeliver("ping #{edeliver_target}")
  end

  defp restart_target(target) do
    target_mix_env = target |> Config.mix_env()
    target |> Config.hosts() |> Enum.each(&restart_host(target_mix_env, &1))
  end

  defp restart_host(target, host) do
    app = Config.app()
    Config.restarter().restart_host(app, target, host)
    :timer.sleep(1_000)
    Config.checker().check_service_status(app, host)
  end
end
