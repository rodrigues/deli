defmodule Deli.HostProvider.Config do
  alias Deli.Config

  @moduledoc """
  Host provider that will return hosts based in
  `config :deli, hosts: [env: [...]]`
  """

  @behaviour Deli.HostProvider

  @impl true
  def hosts(env) do
    env |> Config.hosts() |> Enum.map(&ensure_binary/1)
  end

  defp ensure_binary(b) when is_binary(b), do: b
  defp ensure_binary(x), do: raise("Only string accepted, got: #{inspect(x)}")
end
