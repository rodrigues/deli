defmodule DeliCase do
  use ExUnit.CaseTemplate

  @moduledoc "Basic test case"

  @limit_mismatches 100_000

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
    port_forwarding_timeout
    port_forwarding_wait
    release
    remote_build
    target
    verbose
    versioning
    __system__
    __file_handler__
    __code_handler__
  )a

  using do
    quote do
      use ExUnitProperties
      import unquote(__MODULE__)
      import ExUnit.CaptureIO
      alias Deli.Config
    end
  end

  setup do
    @keys |> Enum.each(&delete_config/1)
  end

  def put_config(key, value) do
    :ok = :deli |> Application.put_env(key, value)
  end

  def delete_config(key) do
    :ok = :deli |> Application.delete_env(key)
  end

  def atom do
    :alphanumeric |> StreamData.atom()
  end

  def string do
    :alphanumeric |> StreamData.string()
  end

  def term_except(predicate) do
    StreamData.term() |> except(predicate)
  end

  def except(data, predicate) do
    data |> StreamData.filter(&(not predicate.(&1)), @limit_mismatches)
  end
end
