defmodule Deli do
  @moduledoc "Defines core types"

  @type app :: atom
  @type env :: atom
  @type host :: String.t()

  defguard is_app(app) when is_atom(app)
  defguard is_env(env) when is_atom(env)
  defguard is_host(host) when is_binary(host)

  if Mix.env() == :test do
    def config_provider, do: ConfigProviderStub
  else
    def config_provider, do: Application
  end
end
