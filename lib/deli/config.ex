defmodule Deli.Config do
  @moduledoc "Provides access to deli configuration"

  @defaults %{
    assets?: false,
    controller: Deli.Controller.Bin,
    docker_build_target: :centos,
    docker_port: 4441,
    # wait in seconds when running `mix deli.shell`
    port_forwarding_timeout: 3_600,
    # wait in ms between port forwarding and iex command
    port_forwarding_wait: 2_000,
    target: :staging,
    verbose?: true,
    versioning: Deli.Versioning.Default,
    yarn?: false
  }

  def app do
    app = :app |> get()
    app || Mix.Project.get().project[:app]
  end

  def app_user(env) do
    app_user = :app_user |> get()

    case app_user do
      nil ->
        app()

      user when is_atom(user) or is_binary(user) ->
        user

      options when is_list(options) ->
        user = options |> Keyword.get(env)
        user || app()
    end
  end

  def assets? do
    :assets |> get(@defaults.assets?)
  end

  def yarn? do
    :yarn |> get(@defaults.yarn?)
  end

  def cookie do
    cookie = :cookie |> get()
    cookie || app()
  end

  def host_id(env, host) do
    "#{app_user(env)}@#{host}"
  end

  def bin_path do
    case :bin_path |> get() do
      nil ->
        app = app()
        "/opt/#{app}/bin/#{app}"

      path ->
        path
    end
  end

  def docker_build_target do
    :docker_build_target |> get(@defaults.docker_build_target)
  end

  def docker_port do
    :docker_port |> get(@defaults.docker_port)
  end

  def port_forwarding_timeout do
    :port_forwarding_timeout |> get(@defaults.port_forwarding_timeout)
  end

  def port_forwarding_wait do
    :port_forwarding_wait |> get(@defaults.port_forwarding_wait)
  end

  def hosts(env) do
    :hosts |> get([]) |> Keyword.get(mix_env(env), [])
  end

  def controller do
    :controller |> get(@defaults.controller)
  end

  def versioning do
    :versioning |> get(@defaults.versioning)
  end

  def verbose? do
    :verbose |> get(@defaults.verbose?)
  end

  def default_target do
    :default_target |> get(@defaults.target)
  end

  def get(key, default \\ nil) do
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
