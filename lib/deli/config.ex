defmodule Deli.Config do
  @moduledoc false

  @defaults %{
    docker_build_target: :centos,
    docker_port: 4441,
    controller: Deli.Controller.Bin
  }

  def app do
    :app |> get(Mix.Project.get().project[:app])
  end

  def docker_build_target do
    :docker_build_target |> get(@defaults.docker_build_target)
  end

  def docker_port do
    :docker_port |> get(@defaults.docker_port)
  end

  def hosts(env) do
    :hosts |> get([]) |> Keyword.get(mix_env(env), [])
  end

  def controller do
    :controller |> get(@defaults.controller)
  end

  def verbose? do
    :verbose |> get(false)
  end

  def get(key, default) do
    :deli |> Application.get_env(key, default)
  end

  def fetch!(key) do
    :deli |> Application.fetch_env!(key)
  end

  def mix_env("production"), do: :prod
  def mix_env(env) when is_atom(env), do: env

  def mix_env(env) when is_binary(env) do
    env |> String.to_atom() |> mix_env()
  end

  def edeliver_target("prod"), do: "production"
  def edeliver_target(:prod), do: "production"
  def edeliver_target(env) when is_atom(env), do: env |> to_string
  def edeliver_target(target) when is_binary(target), do: target
end
