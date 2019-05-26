defmodule DeliCase do
  use ExUnit.CaseTemplate
  import ConfigHelpers
  import Mox

  @moduledoc false

  using do
    quote do
      use ExUnitProperties
      import unquote(__MODULE__)
      import Behaves
      import ConfigHelpers
      import ExUnit.CaptureIO
      import Mox
      import StreamGenerators
      alias Deli.Config
    end
  end

  setup :set_mox_from_context

  setup opts do
    {:ok, pid} = TestAgent.start_link()
    :erlang.put(:test_agent_pid, pid)
    :ok = TestAgent.set(:pid, self())
    {:ok, Map.put(opts, :test_agent, pid)}
  end

  setup opts do
    clear_config()
    mock? = Map.get(opts, :mock, true)
    if mock?, do: setup_mocks()
    :ok
  end

  def setup_mocks do
    put_config(:check, CheckMock)
    put_config(:controller, ControllerMock)
    put_config(:deploy, DeployMock)
    put_config(:host_filter, HostFilterMock)
    put_config(:host_provider, HostProviderMock)
    put_config(:release, ReleaseMock)
    put_config(:versioning, VersioningMock)
  end

  def stub_cmd(result) do
    :ok = TestAgent.set(:cmd, fn _, _, _ -> result end)
  end
end
