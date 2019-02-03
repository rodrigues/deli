defmodule Deli.HostProvider.Config do
  alias Deli.Config

  @moduledoc """
  Host provider that will return hosts based in
  `config :deli, hosts: [env: [...]]`
  """

  @behaviour Deli.HostProvider

  @impl true
  def hosts(env) do
    env |> Config.hosts()
  end
end
