defmodule Deli.Config do
  @moduledoc "Provides access to deli configuration"

  @defaults %{
    assets?: false,
    # use release binary by default
    controller: Deli.Controller.Bin,
    # used when `release` is configured as `Deli.Release.Docker`
    docker_build: [
      # check `Deli.Release.Docker.build_target()` type for all options
      image: {:deli, :centos},
      # in deli images, this user is automatically generated
      # in other docker images, you need to ensure it is created
      user: :deli,
      port: 4441,
      # when app has web assets
      yarn?: false
    ],
    # by default use hosts configured in mix config
    host_provider: Deli.HostProvider.Config,
    # verbose won't output `Deli.Shell` cmd calls, meant for debugging
    output_commands?: false,
    # wait in seconds when running `mix deli.shell`
    port_forwarding_timeout: 3_600,
    # wait in ms between port forwarding and iex command
    port_forwarding_wait: 2_000,
    # use local docker as default release strategy
    release: Deli.Release.Docker,
    # default commands to staging environment
    target: :staging,
    # show processes output
    verbose?: true,
    # git tags like mixfile by default
    versioning: Deli.Versioning.Default
  }

  @spec app() :: Deli.app()
  def app do
    app = :app |> get()
    app || Mix.Project.get().project[:app]
  end

  @spec app_user(Deli.env()) :: atom
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

  @spec assets?() :: boolean
  def assets? do
    :assets |> get(@defaults.assets?)
  end

  @spec cookie() :: atom
  def cookie do
    cookie = :cookie |> get()
    cookie || app()
  end

  @spec host_id(Deli.env(), Deli.host()) :: String.t()
  def host_id(env, host) do
    "#{app_user(env)}@#{host}"
  end

  @spec bin_path :: String.t()
  def bin_path do
    case :bin_path |> get() do
      nil ->
        app = app()
        "/opt/#{app}/bin/#{app}"

      path ->
        path
    end
  end

  @spec docker_build_image() :: Deli.Release.Docker.build_target()
  def docker_build_image do
    :docker_build |> get([]) |> Keyword.get(:port, @defaults.docker_build[:image])
  end

  @spec docker_build_port() :: :inet.port_number()
  def docker_build_port do
    :docker_build |> get([]) |> Keyword.get(:port, @defaults.docker_build[:port])
  end

  @spec docker_build_yarn?() :: boolean
  def docker_build_yarn? do
    :docker_build |> get([]) |> Keyword.get(:yarn?, @defaults.docker_build[:yarn?])
  end

  @spec port_forwarding_timeout() :: pos_integer
  def port_forwarding_timeout do
    :port_forwarding_timeout |> get(@defaults.port_forwarding_timeout)
  end

  @spec port_forwarding_wait() :: non_neg_integer
  def port_forwarding_wait do
    :port_forwarding_wait |> get(@defaults.port_forwarding_wait)
  end

  @doc """
  Returns hosts as configured through `:deli` application config.
  If there is a custom host provider configured, it might not be correct.
  """
  @spec hosts(Deli.env()) :: Enumerable.t()
  def hosts(env) do
    :hosts |> get([]) |> Keyword.get(mix_env(env), [])
  end

  @spec host_provider() :: module
  def host_provider do
    :host_provider |> get(@defaults.host_provider)
  end

  @spec controller() :: module
  def controller do
    :controller |> get(@defaults.controller)
  end

  @spec release() :: module
  def release do
    :release |> get(@defaults.release)
  end

  @spec versioning() :: module
  def versioning do
    :versioning |> get(@defaults.versioning)
  end

  @spec verbose?() :: boolean
  def verbose? do
    :verbose |> get(@defaults.verbose?)
  end

  @spec output_commands?() :: boolean
  def output_commands? do
    :output_commands |> get(@defaults.output_commands?)
  end

  @spec default_target() :: Deli.env()
  def default_target do
    :default_target |> get(@defaults.target)
  end

  @spec get(Application.key(), Application.value()) :: Application.value()
  def get(key, default \\ nil) do
    :deli |> Application.get_env(key, default)
  end

  @spec fetch!(Application.key()) :: Application.value()
  def fetch!(key) do
    :deli |> Application.fetch_env!(key)
  end

  @spec mix_env(atom | String.t()) :: Deli.env()
  def mix_env("production"), do: :prod
  def mix_env(env) when is_atom(env), do: env

  def mix_env(env) when is_binary(env) do
    env |> String.to_atom() |> mix_env()
  end

  @spec edeliver_target(atom | String.t()) :: String.t()
  def edeliver_target("prod"), do: "production"
  def edeliver_target(:prod), do: "production"
  def edeliver_target(env) when is_atom(env), do: env |> to_string
  def edeliver_target(target) when is_binary(target), do: target
end
