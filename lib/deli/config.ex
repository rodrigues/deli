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
    app = app || Mix.Project.get().project[:app]
    app |> ensure_atom
  end

  @spec app_user(Deli.env()) :: atom
  def app_user(env) do
    app_user = :app_user |> get()

    app_user =
      case app_user do
        nil ->
          app()

        user when is_atom(user) or is_binary(user) ->
          user

        options when is_list(options) ->
          user = options |> Keyword.get(env)
          user || app()
      end

    app_user |> ensure_atom
  end

  @spec assets?() :: boolean
  def assets? do
    :assets |> get(@defaults.assets?) |> ensure_boolean
  end

  @spec cookie() :: atom
  def cookie do
    cookie = :cookie |> get()
    cookie = cookie || app()
    cookie |> ensure_atom
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

      path when is_binary(path) ->
        path
    end
  end

  @spec docker_build_image() :: Deli.Release.Docker.build_target()
  def docker_build_image do
    :docker_build |> get([]) |> Keyword.get(:port, @defaults.docker_build[:image])
  end

  @spec docker_build_port() :: :inet.port_number()
  def docker_build_port do
    :docker_build
    |> get([])
    |> Keyword.get(:port, @defaults.docker_build[:port])
    |> ensure_port_number
  end

  @spec docker_build_yarn?() :: boolean
  def docker_build_yarn? do
    :docker_build
    |> get([])
    |> Keyword.get(:yarn?, @defaults.docker_build[:yarn?])
    |> ensure_boolean
  end

  @spec port_forwarding_timeout() :: pos_integer
  def port_forwarding_timeout do
    :port_forwarding_timeout
    |> get(@defaults.port_forwarding_timeout)
    |> ensure_pos_integer
  end

  @spec port_forwarding_wait() :: pos_integer
  def port_forwarding_wait do
    :port_forwarding_wait
    |> get(@defaults.port_forwarding_wait)
    |> ensure_pos_integer
  end

  @doc """
  Returns hosts as configured through `:deli` application config.
  If there is a custom host provider configured, it might not be correct.
  """
  @spec hosts(Deli.env()) :: [Deli.host()]
  def hosts(env) do
    :hosts
    |> get([])
    |> Keyword.get(mix_env(env), [])
    |> Enum.map(&ensure_binary/1)
  end

  @spec host_provider() :: module
  def host_provider do
    :host_provider
    |> get(@defaults.host_provider)
    |> ensure_atom
  end

  @spec controller() :: module
  def controller do
    :controller
    |> get(@defaults.controller)
    |> ensure_atom
  end

  @spec release() :: module
  def release do
    :release
    |> get(@defaults.release)
    |> ensure_atom
  end

  @spec versioning() :: module
  def versioning do
    :versioning
    |> get(@defaults.versioning)
    |> ensure_atom
  end

  @spec verbose?() :: boolean
  def verbose? do
    :verbose
    |> get(@defaults.verbose?)
    |> ensure_boolean
  end

  @spec output_commands?() :: boolean
  def output_commands? do
    :output_commands
    |> get(@defaults.output_commands?)
    |> ensure_boolean
  end

  @spec default_target() :: Deli.env()
  def default_target do
    :default_target
    |> get(@defaults.target)
    |> ensure_atom
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
  def edeliver_target(env) when is_atom(env), do: env |> Atom.to_string()
  def edeliver_target(target) when is_binary(target), do: target

  defp ensure_boolean(b) when b in [true, false], do: b
  defp ensure_boolean(x), do: raise("Only boolean accepted, got: #{inspect(x)}")

  defp ensure_atom(a) when is_atom(a), do: a
  defp ensure_atom(x), do: raise("Only atom accepted, got: #{inspect(x)}")

  defp ensure_port_number(i) when i in 0..65535, do: i
  defp ensure_port_number(x), do: raise("Only port number accepted, got: #{inspect(x)}")

  defp ensure_pos_integer(i) when is_integer(i) and i > 0, do: i
  defp ensure_pos_integer(x), do: raise("Only positive integer accepted, got: #{inspect(x)}")

  defp ensure_binary(s) when is_binary(s), do: s
  defp ensure_binary(x), do: raise("Only string accepted, got: #{inspect(x)}")
end
