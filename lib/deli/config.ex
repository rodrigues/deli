defmodule Deli.Config do
  @default_docker_build_target :centos
  @default_docker_port 4441

  def app do
    :app |> get(Mix.Project.get().project[:app])
  end

  def docker_build_target do
    :docker_build_target |> get(@default_docker_build_target)
  end

  def docker_port do
    :docker_port |> get(@default_docker_port)
  end

  def hosts(env) do
    :hosts |> get([]) |> Keyword.get(mix_env(env), [])
  end

  def get(key, default) do
    :deli |> Application.get_env(key, default)
  end

  def fetch!(key) do
    :deli |> Application.fetch_env!(key)
  end

  def mix_env("production"), do: :prod

  def mix_env(env) when is_binary(env) do
    env |> String.to_atom() |> mix_env()
  end

  def mix_env(env) when is_atom(env), do: env
end
