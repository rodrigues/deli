defmodule Deli.HostProvider.Config do
  import Deli, only: [is_env: 1]
  import Deli.Config.Ensure, only: [ensure_binary: 1]
  alias Deli.Config

  @moduledoc """
  Host provider that will return hosts based in
  `config :deli, hosts: [env: [...]]`
  """

  @behaviour Deli.HostProvider

  @impl true
  def hosts(env) when is_env(env) do
    env |> Config.hosts() |> Enum.map(&ensure_binary/1)
  end
end
