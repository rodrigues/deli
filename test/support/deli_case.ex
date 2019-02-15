defmodule DeliCase do
  use ExUnit.CaseTemplate
  import Mox

  @moduledoc false

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
  )a

  using do
    quote do
      use ExUnitProperties
      import unquote(__MODULE__)
      import ExUnit.CaptureIO
      import Mox
      alias Deli.Config
      alias TestAgent
    end
  end

  setup :set_mox_global

  setup opts do
    @keys |> Enum.each(&delete_config/1)
    waits() |> Enum.each(&put_config(:waits, &1, 1))

    mock? = opts |> Map.get(:mock, true)
    if mock?, do: setup_mocks()

    put_config(:verbose, false)
    :ok = TestAgent.clear()
    :ok = :pid |> TestAgent.set(self())
  end

  def setup_mocks do
    put_config(:controller, ControllerMock)
    put_config(:host_provider, HostProviderMock)
    put_config(:release, ReleaseMock)
    put_config(:versioning, VersioningMock)
  end

  def waits, do: @waits

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

  def atom do
    :alphanumeric |> StreamData.atom()
  end

  def string do
    :alphanumeric |> StreamData.string()
  end

  def nonempty_string(type \\ :alphanumeric) do
    type |> StreamData.string() |> except(&empty_string?/1)
  end

  def term_except(predicate) do
    StreamData.term() |> except(predicate)
  end

  def except(data, predicate) do
    data |> StreamData.filter(&(not predicate.(&1)), @limit_mismatches)
  end

  def empty_string?(""), do: true
  def empty_string?(_), do: false

  def stub_cmd(result) do
    :ok = :cmd |> TestAgent.set(fn _, _, _ -> result end)
  end
end
