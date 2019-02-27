defmodule Deli.Config do
  import Deli, only: [is_env: 1, is_host: 1]
  import Deli.Config.Ensure

  @moduledoc "Provides access to deli configuration"

  @defaults %{
    assets?: false,
    # use release binary by default
    controller: Deli.Controller.Bin,
    # used when `release` is configured as `Deli.Release.Docker`
    docker_build: [
      # check `Deli.Release.Docker.build_target()` type for all options
      image: {:deli, :centos},
      # needs to be available in nodesource.com
      node_version: "9.x",
      port: 4441,
      # in deli images, this user is automatically generated
      # in other docker images, you need to ensure it is created
      user: :deli,
      # when app has web assets
      yarn?: false
    ],
    # by default use hosts configured in mix config
    host_provider: Deli.HostProvider.Config,
    # verbose won't output `Deli.Shell` cmd calls, meant for debugging
    output_commands?: false,
    # wait in seconds when running `mix deli.shell`
    port_forwarding_timeout: 3_600,
    # use local docker as default release strategy
    release: Deli.Release.Docker,
    # used when `release` is configured as `Deli.Release.Remote`
    remote_build: [
      user: :deli,
      host: "localhost"
    ],
    waits: [
      # wait in ms between port forwarding and iex command
      port_forwarding: 2_000,
      # wait in ms between start_host and check if it's ok
      started_check: 1_000,
      # wait in ms between stop_host and check if it's ok
      stopped_check: 1_000
    ],
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
    app = app || project()[:app]
    app |> ensure_atom
  end

  @spec app_user(Deli.env()) :: atom
  def app_user(env) when is_env(env) do
    app_user = :app_user |> get()

    app_user =
      case app_user do
        user when is_atom(user) or is_binary(user) ->
          user || app()

        options when is_list(options) ->
          user = options |> Keyword.get(env)
          user || app()

        _ ->
          app()
      end

    app_user |> ensure_atom_or_binary
  end

  @spec assets?() :: boolean
  def assets? do
    :assets |> get(@defaults.assets?) |> ensure_boolean
  end

  @spec bin_path :: String.t()
  def bin_path do
    case :bin_path |> get() do
      nil ->
        app = app()
        "/opt/#{app}/bin/#{app}"

      path when is_binary(path) ->
        path
    end
  end

  @spec controller() :: module
  def controller do
    :controller
    |> get(@defaults.controller)
    |> ensure_atom
  end

  @spec cookie() :: atom
  def cookie do
    cookie = :cookie |> get()
    cookie = cookie || app()
    cookie |> ensure_atom
  end

  @spec default_target() :: Deli.env()
  def default_target do
    :default_target
    |> get(@defaults.target)
    |> ensure_atom
  end

  @spec docker_build_image() :: Deli.Release.Docker.build_target()
  def docker_build_image do
    :docker_build |> get([]) |> Keyword.get(:image, @defaults.docker_build[:image])
  end

  @spec docker_build_node_version() :: String.t()
  def docker_build_node_version do
    :docker_build
    |> get([])
    |> Keyword.get(:node_version, @defaults.docker_build[:node_version])
    |> ensure_binary
  end

  @spec docker_build_port() :: :inet.port_number()
  def docker_build_port do
    :docker_build
    |> get([])
    |> Keyword.get(:port, @defaults.docker_build[:port])
    |> ensure_port_number
  end

  @spec docker_build_user() :: atom
  def docker_build_user do
    :docker_build
    |> get([])
    |> Keyword.get(:user, @defaults.docker_build[:user])
    |> ensure_atom
  end

  @spec docker_build_yarn?() :: boolean
  def docker_build_yarn? do
    :docker_build
    |> get([])
    |> Keyword.get(:yarn, @defaults.docker_build[:yarn?])
    |> ensure_boolean
  end

  @doc """
  Returns hosts as configured through `:deli` application config.
  If there is a custom host provider configured, it might not be correct.
  """
  @spec hosts(Deli.env()) :: [Deli.host()]
  def hosts(env) when is_env(env) do
    :hosts
    |> get([])
    |> Keyword.get(mix_env(env), [])
    |> Enum.map(&ensure_binary/1)
  end

  @spec host_id(Deli.env(), Deli.host()) :: String.t()
  def host_id(env, host) when is_env(env) and is_host(host) do
    "#{app_user(env)}@#{host}"
  end

  @spec host_provider() :: module
  def host_provider do
    :host_provider
    |> get(@defaults.host_provider)
    |> ensure_atom
  end

  @spec output_commands?() :: boolean
  def output_commands? do
    :output_commands
    |> get(@defaults.output_commands?)
    |> ensure_boolean
  end

  @spec port_forwarding_timeout() :: pos_integer
  def port_forwarding_timeout do
    :port_forwarding_timeout
    |> get(@defaults.port_forwarding_timeout)
    |> ensure_pos_integer
  end

  @spec release() :: module
  def release do
    :release
    |> get(@defaults.release)
    |> ensure_atom
  end

  @spec remote_build_host() :: Deli.host()
  def remote_build_host do
    :remote_build
    |> get([])
    |> Keyword.get(:host, @defaults.remote_build[:host])
    |> ensure_binary
  end

  @spec remote_build_user() :: atom
  def remote_build_user do
    :remote_build
    |> get([])
    |> Keyword.get(:user, @defaults.remote_build[:user])
    |> ensure_atom
  end

  @spec verbose?() :: boolean
  def verbose? do
    :verbose
    |> get(@defaults.verbose?)
    |> ensure_boolean
  end

  @spec versioning() :: module
  def versioning do
    :versioning
    |> get(@defaults.versioning)
    |> ensure_atom
  end

  @spec wait(atom) :: pos_integer
  def wait(key) do
    :waits
    |> get([])
    |> Keyword.get(key, @defaults.waits[key])
    |> ensure_pos_integer
  end

  @spec __system__() :: module
  def __system__ do
    :__system__
    |> get(System)
    |> ensure_atom
  end

  @spec __file_handler__() :: module
  def __file_handler__ do
    :__file_handler__
    |> get(File)
    |> ensure_atom
  end

  @spec __code_handler__() :: module
  def __code_handler__ do
    :__code_handler__
    |> get(Code)
    |> ensure_atom
  end

  @spec get(Application.key(), Application.value()) :: Application.value()
  def get(key, default \\ nil) when is_atom(key) do
    :deli |> Application.get_env(key, default)
  end

  @spec fetch!(Application.key()) :: Application.value()
  def fetch!(key) when is_atom(key) do
    :deli |> Application.fetch_env!(key)
  end

  @spec mix_env(Deli.env() | String.t()) :: Deli.env()
  def mix_env("production"), do: :prod
  def mix_env(:production), do: :prod
  def mix_env(env) when is_env(env), do: env

  def mix_env(env) when is_binary(env) do
    env |> String.to_atom() |> mix_env()
  end

  @spec edeliver_target(Deli.env() | String.t()) :: String.t()
  def edeliver_target("prod"), do: "production"
  def edeliver_target(:prod), do: "production"
  def edeliver_target(env) when is_env(env), do: env |> Atom.to_string()
  def edeliver_target(target) when is_binary(target), do: target

  @spec project(module | nil) :: Keyword.t()
  def project(mix_project \\ nil) do
    mix_project = mix_project || Mix.Project.get()
    mix_project.project
  end

  @spec version(module | nil) :: Version.t()
  def version(mix_project \\ nil) do
    project(mix_project)[:version] |> Version.parse!()
  end
end
