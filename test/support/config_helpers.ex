defmodule ConfigHelpers do
  @moduledoc false

  @keys ~w(
    app
    app_user
    assets
    bin_path
    check
    controller
    cookie
    default_target
    deploy
    docker_build
    hosts
    host_filter
    host_provider
    output_commands
    release
    remote_build
    verbose
    versioning
    waits
    __application_handler__
    __code_handler__
    __file_handler__
    __system_handler__
  )a

  @waits ~w(
    port_forwarding
    started_check
    stopped_check
  )a

  def config_keys, do: @keys
  def waits, do: @waits

  def clear_config do
    Enum.each(config_keys(), &delete_config/1)
    Enum.each(waits(), &put_config(:waits, &1, 1))

    put_config(:verbose, false)
  end

  def get_config(key) do
    Application.get_env(:deli, key)
  end

  def put_config(key, value) do
    :ok = Application.put_env(:deli, key, value)
  end

  def put_config(outer_key, inner_key, inner_value) do
    new_outer_value =
      outer_key
      |> get_config()
      |> Kernel.||([])
      |> Keyword.put(inner_key, inner_value)

    put_config(outer_key, new_outer_value)
  end

  def delete_config(key) do
    :ok = Application.delete_env(:deli, key)
  end
end
