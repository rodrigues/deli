defmodule Deli.ConfigTest do
  use ExUnit.Case
  use ExUnitProperties
  import StreamDataExclude
  alias Deli.Config

  @default_app :deli

  def put_config(key, value) do
    :ok = :deli |> Application.put_env(key, value)
  end

  def delete_config(key) do
    :ok = :deli |> Application.delete_env(key)
  end

  describe "app/0" do
    test "uses mix project app when app not configured" do
      delete_config(:app)
      assert Config.app() == @default_app
    end

    property "returns app configured when atom" do
      check all a <- :alphanumeric |> atom() do
        put_config(:app, a)
        assert Config.app() == a
      end
    end

    property "fails when app configured but not an atom" do
      check all a <- term_except(&is_atom/1) do
        put_config(:app, a)
        assert_raise RuntimeError, &Config.app/0
      end
    end
  end

  describe "app_user/1" do
    property "fails if `env` is not an atom" do
      check all a <- term_except(&is_atom/1) do
        call = fn -> Config.app_user(a) end
        assert_raise FunctionClauseError, call
      end
    end

    property "returns app when not configured" do
      check all a <- :alphanumeric |> atom() do
        put_config(:app, a)
        delete_config(:app_user)
        assert Config.app_user(:staging) == a
        assert Config.app_user(:prod) == a
      end
    end

    property "returns app_user configured when atom" do
      check all a <- :alphanumeric |> atom() do
        put_config(:app_user, a)
        assert Config.app_user(:staging) == a
        assert Config.app_user(:prod) == a
      end
    end

    property "returns app_user configured when binary" do
      check all a <- binary() do
        put_config(:app_user, a)
        assert Config.app_user(:staging) == a
        assert Config.app_user(:prod) == a
      end
    end

    property "returns env specific user when configured as such" do
      check all s <- :alphanumeric |> atom(),
                p <- :alphanumeric |> atom() do
        put_config(:app_user, staging: s, prod: p)
        assert Config.app_user(:staging) == s
        assert Config.app_user(:prod) == p
      end
    end

    property "returns app if app_user is configured as something else" do
      check all a <- :alphanumeric |> atom(),
                b <- term_except(&(is_atom(&1) or is_binary(&1))) do
        put_config(:app, a)
        put_config(:app_user, b)
        assert Config.app_user(:staging) == a
      end
    end
  end

  describe "assets?/0" do
    test "returns false when not configured" do
      delete_config(:assets)
      assert Config.assets?() == false
    end

    property "returns assets? when configured as boolean" do
      check all a <- boolean() do
        put_config(:assets, a)
        assert Config.assets?() == a
      end
    end

    property "fails when configured as something else" do
      check all a <- term_except(&is_boolean/1) do
        put_config(:assets, a)
        assert_raise RuntimeError, &Config.assets?/0
      end
    end
  end

  describe "bin_path/0" do
    test "returns default bin path when not configured" do
      put_config(:app, :fish)
      delete_config(:bin_path)
      assert Config.bin_path() == "/opt/fish/bin/fish"
    end

    property "returns path when binary" do
      check all a <- binary() do
        put_config(:bin_path, a)
        assert Config.bin_path() == a
      end
    end

    property "fails when path is configured as something other than a binary" do
      check all a <- term_except(&is_binary/1) do
        put_config(:bin_path, a)
        assert_raise CaseClauseError, &Config.bin_path/0
      end
    end
  end

  describe "controller/0" do
    test "returns default controller when not configured" do
      delete_config(:controller)
      assert Config.controller() == Deli.Controller.Bin
    end

    property "returns controller when configured as atom" do
      check all a <- :alphanumeric |> atom() do
        put_config(:controller, a)
        assert Config.controller() == a
      end
    end

    property "fails when configured as something else" do
      check all a <- term_except(&is_atom/1) do
        put_config(:controller, a)
        assert_raise RuntimeError, &Config.controller/0
      end
    end
  end

  describe "cookie/0" do
    test "returns app when not configured" do
      delete_config(:app)
      delete_config(:cookie)
      assert Config.cookie() == @default_app
    end

    property "returns cookie when configured as atom" do
      check all a <- :alphanumeric |> atom() do
        put_config(:cookie, a)
        assert Config.cookie() == a
      end
    end

    property "fails when configured as something else" do
      check all a <- term_except(&is_atom/1) do
        put_config(:cookie, a)
        assert_raise RuntimeError, &Config.cookie/0
      end
    end
  end

  describe "default_target/0" do
    test "returns staging when not configured" do
      delete_config(:default_target)
      assert Config.default_target() == :staging
    end

    property "returns default_target when configured as atom" do
      check all a <- :alphanumeric |> atom() do
        put_config(:default_target, a)
        assert Config.default_target() == a
      end
    end

    property "fails when configured as something else" do
      check all a <- term_except(&is_atom/1) do
        put_config(:default_target, a)
        assert_raise RuntimeError, &Config.default_target/0
      end
    end
  end

  describe "docker_build_image/0" do
    test "returns default image when not configured" do
      delete_config(:docker_build)
      assert Config.docker_build_image() == {:deli, :centos}
    end

    property "returns docker build image when configured" do
      check all a <- term() do
        put_config(:docker_build, image: a)
        assert Config.docker_build_image() == a
      end
    end
  end

  describe "docker_build_port/0" do
    test "returns default port when not configured" do
      delete_config(:docker_build)
      assert Config.docker_build_port() == 4441
    end

    property "returns docker build port when configured" do
      check all a <- integer(0..65_535) do
        put_config(:docker_build, port: a)
        assert Config.docker_build_port() == a
      end
    end
  end

  describe "docker_build_yarn?/0" do
    test "returns false when not configured" do
      delete_config(:docker_build)
      refute Config.docker_build_yarn?()
    end

    property "returns value when configured as boolean" do
      check all a <- boolean() do
        put_config(:docker_build, yarn?: a)
        assert Config.docker_build_yarn?() == a
      end
    end

    property "fails when configured as something else" do
      check all a <- term_except(&is_boolean/1) do
        put_config(:docker_build, yarn?: a)
        assert_raise RuntimeError, &Config.docker_build_yarn?/0
      end
    end
  end

  describe "hosts/1" do
    test "returns empty if not configured" do
      check all a <- :alphanumeric |> atom() do
        delete_config(:hosts)
        assert Config.hosts(a) == []
      end
    end

    property "returns value when configured as binary list" do
      check all env <- :alphanumeric |> atom(),
                hosts <- list_of(binary()) do
        put_config(:hosts, [{env, hosts}])
        assert Config.hosts(env) == hosts
      end
    end

    property "fails when configured not as a list" do
      check all env <- :alphanumeric |> atom(),
                hosts <- term_except(&(is_list(&1) or &1 == %{})) do
        put_config(:hosts, [{env, hosts}])
        assert catch_error(Config.hosts(env))
      end
    end

    property "fails when env is not an atom" do
      check all env <- term_except(&is_atom/1) do
        assert_raise FunctionClauseError, fn -> Config.hosts(env) end
      end
    end
  end

  describe "host_id/2" do
    test "returns ssh user@host identifier" do
      check all env <- :alphanumeric |> atom(),
                app_user <- :alphanumeric |> atom(),
                host <- binary() do
        put_config(:app_user, [{env, app_user}])
        assert Config.host_id(env, host) == "#{app_user}@#{host}"
      end
    end

    property "fails if env not an atom" do
      check all env <- term_except(&is_atom/1),
                host <- binary() do
        assert_raise FunctionClauseError, fn -> Config.host_id(env, host) end
      end
    end

    property "fails if host not a binary" do
      check all env <- :alphanumeric |> atom(),
                host <- term_except(&is_binary/1) do
        assert_raise FunctionClauseError, fn -> Config.host_id(env, host) end
      end
    end
  end

  describe "host_provider/0" do
    test "returns default host provider when not configured" do
      delete_config(:host_provider)
      assert Config.host_provider() == Deli.HostProvider.Config
    end

    property "returns host provider when configured as atom" do
      check all a <- :alphanumeric |> atom() do
        put_config(:host_provider, a)
        assert Config.host_provider() == a
      end
    end

    property "fails when configured as something else" do
      check all a <- term_except(&is_atom/1) do
        put_config(:host_provider, a)
        assert_raise RuntimeError, &Config.host_provider/0
      end
    end
  end

  describe "output_commands?/0" do
    test "returns false when not configured" do
      delete_config(:output_commands)
      refute Config.output_commands?()
    end

    property "returns value when configured as boolean" do
      check all a <- boolean() do
        put_config(:output_commands, a)
        assert Config.output_commands?() == a
      end
    end

    property "fails when configured as something else" do
      check all a <- term_except(&is_boolean/1) do
        put_config(:output_commands, a)
        assert_raise RuntimeError, &Config.output_commands?/0
      end
    end
  end

  describe "port_forwarding_timeout/0" do
    test "returns default timeout when not configured" do
      delete_config(:port_forwarding_timeout)
      assert Config.port_forwarding_timeout() == 3600
    end

    property "returns port forwarding timeout when configured" do
      check all a <- positive_integer() do
        put_config(:port_forwarding_timeout, a)
        assert Config.port_forwarding_timeout() == a
      end
    end

    property "fails when configured as something else" do
      check all a <- term_except(&(is_integer(&1) and &1 > 0)) do
        put_config(:port_forwarding_timeout, a)
        assert catch_error(Config.port_forwarding_timeout())
      end
    end
  end
end
