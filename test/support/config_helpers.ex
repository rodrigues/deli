defmodule ConfigHelpers do
  @moduledoc false

  @keys ~w(
    app
    app_user
    assets
    bin_path
    controller
    cookie
    default_target
    docker_build
    hosts
    host_provider
    output_commands
    release
    remote_build
    target
    verbose
    versioning
    waits
    __system__
    __file_handler__
    __code_handler__
  )a

  @waits ~w(
    port_forwarding
    started_check
    stopped_check
  )a

  def config_keys, do: @keys
  def waits, do: @waits

  def clear_config do
    config_keys() |> Enum.each(&delete_config/1)
    waits() |> Enum.each(&put_config(:waits, &1, 1))

    put_config(:verbose, false)
  end

  def get_config(key) do
    :deli |> Application.get_env(key)
  end

  def put_config(key, value) do
    :ok = :deli |> Application.put_env(key, value)
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
    :ok = :deli |> Application.delete_env(key)
  end
end
