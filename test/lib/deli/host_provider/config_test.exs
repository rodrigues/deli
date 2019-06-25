defmodule Deli.HostProvider.ConfigTest do
  use DeliCase, async: true
  alias Deli.HostProvider.Config

  test "behaviour" do
    assert behaves?(Config, Deli.HostProvider)
  end

  describe "hosts/1" do
    property "config hosts" do
      check all env <- env(),
                hosts <- hosts() do
        put_config(:hosts, [{env, hosts}])
        assert Config.hosts(env) == hosts
      end
    end
  end
end
