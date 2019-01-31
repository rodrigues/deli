defmodule Deli.HostProvider.Config do
  alias Deli.Config

  @moduledoc """
  Host provider that will return hosts based in
  `config `:deli`, `hosts: [env: [...]]`
  """

  @behaviour Deli.HostProvider

  @impl true
  def hosts(env) do
    env |> Config.hosts()
  end

  @impl true
  def count(env) do
    env |> hosts |> Enum.count()
  end
end
