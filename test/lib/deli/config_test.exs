defmodule Deli.ConfigTest do
  use DeliCase
  import Deli, only: [is_app: 1, is_env: 1, is_host: 1]

  describe "app/0" do
    test "uses mix project app when app not configured" do
      delete_config(:app)
      assert Config.app() == :deli
    end

    property "app configured correctly" do
      check all app <- app() do
        put_config(:app, app)
        assert Config.app() == app
      end
    end

    property "fails when app is invalid" do
      check all app <- term_except(&is_app/1) do
        put_config(:app, app)
        assert_raise RuntimeError, &Config.app/0
      end
    end
  end

  describe "app_user/1" do
    property "fails when env is invalid" do
      check all env <- term_except(&is_env/1) do
        call = fn -> Config.app_user(env) end
        assert_raise FunctionClauseError, call
      end
    end

    property "app when not configured" do
      check all app <- app(),
                env <- env() do
        put_config(:app, app)
        delete_config(:app_user)

        assert Config.app_user(:staging) == app
        assert Config.app_user(:prod) == app
        assert Config.app_user(env) == app
      end
    end

    property "app_user when configured solo" do
      check all app_user <- app_user() do
        put_config(:app_user, app_user)
        assert Config.app_user(:staging) == app_user
        assert Config.app_user(:prod) == app_user
      end
    end

    property "env specific user when configured correctly" do
      check all staging_user <- app_user(),
                prod_user <- app_user() do
        put_config(:app_user, staging: staging_user, prod: prod_user)
        assert Config.app_user(:staging) == staging_user
        assert Config.app_user(:prod) == prod_user
      end
    end

    property "app when app_user is invalid" do
      check all app <- app(),
                app_user <- term_except(&(is_atom(&1) or is_binary(&1))) do
        put_config(:app, app)
        put_config(:app_user, app_user)
        assert Config.app_user(:staging) == app
      end
    end
  end

  describe "assets?/0" do
    test "false when not configured" do
      delete_config(:assets)
      assert Config.assets?() == false
    end

    property "returns assets? when configured correctly" do
      check all assets? <- boolean() do
        put_config(:assets, assets?)
        assert Config.assets?() == assets?
      end
    end

    property "fails when is invalid" do
      check all assets? <- term_except(&is_boolean/1) do
        put_config(:assets, assets?)
        assert_raise RuntimeError, &Config.assets?/0
      end
    end
  end

  describe "bin_path/0" do
    test "default bin path when not configured" do
      put_config(:app, :fish)
      delete_config(:bin_path)
      assert Config.bin_path() == "/opt/fish/bin/fish"
    end

    property "path when configured correctly" do
      check all path <- binary() do
        put_config(:bin_path, path)
        assert Config.bin_path() == path
      end
    end

    property "fails when path is invalid" do
      check all path <- term_except(&is_binary/1) do
        put_config(:bin_path, path)
        assert_raise CaseClauseError, &Config.bin_path/0
      end
    end
  end

  describe "controller/0" do
    test "default controller when not configured" do
      delete_config(:controller)
      assert Config.controller() == Deli.Controller.Bin
    end

    property "controller when configured correctly" do
      check all controller <- atom() do
        put_config(:controller, controller)
        assert Config.controller() == controller
      end
    end

    property "fails when invalid" do
      check all controller <- term_except(&is_atom/1) do
        put_config(:controller, controller)
        assert_raise RuntimeError, &Config.controller/0
      end
    end
  end

  describe "cookie/0" do
    test "app when not configured" do
      check all app <- app() do
        put_config(:app, app)
        delete_config(:cookie)
        assert Config.cookie() == app
      end
    end

    property "cookie when configured correctly" do
      check all cookie <- atom() do
        put_config(:cookie, cookie)
        assert Config.cookie() == cookie
      end
    end

    property "fails when cookie is invalid" do
      check all cookie <- term_except(&is_atom/1) do
        put_config(:cookie, cookie)
        assert_raise RuntimeError, &Config.cookie/0
      end
    end
  end

  describe "default_target/0" do
    test "staging when not configured" do
      delete_config(:default_target)
      assert Config.default_target() == :staging
    end

    property "default_target when configured correctly" do
      check all env <- env() do
        put_config(:default_target, env)
        assert Config.default_target() == env
      end
    end

    property "fails when is invalid" do
      check all env <- term_except(&is_env/1) do
        put_config(:default_target, env)
        assert_raise RuntimeError, &Config.default_target/0
      end
    end
  end

  describe "docker_build_image/0" do
    test "default image when not configured" do
      delete_config(:docker_build)
      assert Config.docker_build_image() == {:deli, :centos}
    end

    property "docker build image when configured" do
      check all image <- term() do
        put_config(:docker_build, image: image)
        assert Config.docker_build_image() == image
      end
    end
  end

  describe "docker_build_node_version/0" do
    test "default version when not configured" do
      delete_config(:node_version)
      assert Config.docker_build_node_version() == "9.x"
    end

    property "provided version when configured correctly" do
      check all node_version <- nonempty_string() do
        put_config(:docker_build, node_version: node_version)
        assert Config.docker_build_node_version() == node_version
      end
    end

    property "fails when is invalid" do
      check all node_version <- term_except(&is_binary/1) do
        put_config(:docker_build, node_version: node_version)
        assert_raise RuntimeError, &Config.docker_build_node_version/0
      end
    end
  end

  describe "docker_build_port/0" do
    test "default port when not configured" do
      delete_config(:docker_build)
      assert Config.docker_build_port() == 4441
    end

    property "docker build port when configured correctly" do
      check all port <- 0..65_535 |> integer() do
        put_config(:docker_build, port: port)
        assert Config.docker_build_port() == port
      end
    end

    property "fails when is invalid" do
      check all port <- term_except(&is_integer/1) do
        put_config(:docker_build, port: port)
        assert_raise RuntimeError, &Config.docker_build_port/0
      end
    end
  end

  describe "docker_build_user/0" do
    test "deli when not configured" do
      delete_config(:docker_build)
      assert Config.docker_build_user() == :deli
    end

    property "docker build user when configured correctly" do
      check all user <- atom() do
        put_config(:docker_build, user: user)
        assert Config.docker_build_user() == user
      end
    end

    property "fails when is invalid" do
      check all user <- term_except(&is_atom/1) do
        put_config(:docker_build, user: user)
        assert_raise RuntimeError, &Config.docker_build_user/0
      end
    end
  end

  describe "docker_build_yarn?/0" do
    test "false when not configured" do
      delete_config(:docker_build)
      refute Config.docker_build_yarn?()
    end

    property "value when configured correctly" do
      check all yarn? <- boolean() do
        put_config(:docker_build, yarn: yarn?)
        assert Config.docker_build_yarn?() == yarn?
      end
    end

    property "fails when is invalid" do
      check all yarn? <- term_except(&is_boolean/1) do
        put_config(:docker_build, yarn: yarn?)
        assert_raise RuntimeError, &Config.docker_build_yarn?/0
      end
    end
  end

  describe "hosts/1" do
    test "empty if not configured" do
      check all env <- env() do
        delete_config(:hosts)
        assert Config.hosts(env) == []
      end
    end

    property "value when configured correctly" do
      check all env <- env(),
                hosts <- hosts() do
        put_config(:hosts, [{env, hosts}])
        assert Config.hosts(env) == hosts
      end
    end

    property "fails when is invalid" do
      check all env <- env(),
                hosts <- term_except(&(is_list(&1) or &1 == %{})) do
        put_config(:hosts, [{env, hosts}])
        assert catch_error(Config.hosts(env))
      end
    end

    property "fails when env is invalid" do
      check all env <- term_except(&is_env/1) do
        assert_raise FunctionClauseError, fn -> Config.hosts(env) end
      end
    end
  end

  describe "host_id/2" do
    test "ssh user@host identifier" do
      check all env <- env(),
                app_user <- app_user(),
                host <- host() do
        put_config(:app_user, [{env, app_user}])
        assert Config.host_id(env, host) == "#{app_user}@#{host}"
      end
    end

    property "fails if env not an atom" do
      check all env <- term_except(&is_env/1),
                host <- host() do
        assert_raise FunctionClauseError, fn -> Config.host_id(env, host) end
      end
    end

    property "fails if host not a binary" do
      check all env <- env(),
                host <- term_except(&is_host/1) do
        assert_raise FunctionClauseError, fn -> Config.host_id(env, host) end
      end
    end
  end

  describe "host_provider/0" do
    test "default host provider when not configured" do
      delete_config(:host_provider)
      assert Config.host_provider() == Deli.HostProvider.Config
    end

    property "host provider when configured correctly" do
      check all host_provider <- atom() do
        put_config(:host_provider, host_provider)
        assert Config.host_provider() == host_provider
      end
    end

    property "fails when is invalid" do
      check all host_provider <- term_except(&is_atom/1) do
        put_config(:host_provider, host_provider)
        assert_raise RuntimeError, &Config.host_provider/0
      end
    end
  end

  describe "output_commands?/0" do
    test "false when not configured" do
      delete_config(:output_commands)
      refute Config.output_commands?()
    end

    property "value when configured correctly" do
      check all output? <- boolean() do
        put_config(:output_commands, output?)
        assert Config.output_commands?() == output?
      end
    end

    property "fails when is invalid" do
      check all output? <- term_except(&is_boolean/1) do
        put_config(:output_commands, output?)
        assert_raise RuntimeError, &Config.output_commands?/0
      end
    end
  end

  describe "release/0" do
    test "default release strategy when not configured" do
      delete_config(:release)
      assert Config.release() == Deli.Release.Docker
    end

    property "release strategy when configured correctly" do
      check all release <- atom() do
        put_config(:release, release)
        assert Config.release() == release
      end
    end

    property "fails when is invalid" do
      check all release <- term_except(&is_atom/1) do
        put_config(:release, release)
        assert_raise RuntimeError, &Config.release/0
      end
    end
  end

  describe "remote_build_host/0" do
    test "localhost when not configured" do
      delete_config(:remote_build)
      assert Config.remote_build_host() == "localhost"
    end

    property "host when configured correctly" do
      check all host <- host() do
        put_config(:remote_build, host: host)
        assert Config.remote_build_host() == host
      end
    end

    property "fails when is invalid" do
      check all host <- term_except(&is_host/1) do
        put_config(:remote_build, host: host)
        assert_raise RuntimeError, &Config.remote_build_host/0
      end
    end
  end

  describe "remote_build_user/0" do
    test "deli when not configured" do
      delete_config(:remote_build)
      assert Config.remote_build_user() == :deli
    end

    property "user when configured correctly" do
      check all user <- atom() do
        put_config(:remote_build, user: user)
        assert Config.remote_build_user() == user
      end
    end

    property "fails when is invalid" do
      check all user <- term_except(&is_atom/1) do
        put_config(:remote_build, user: user)
        assert_raise RuntimeError, &Config.remote_build_user/0
      end
    end
  end

  describe "versioning/0" do
    test "default versioning strategy when not configured" do
      delete_config(:versioning)
      assert Config.versioning() == Deli.Versioning.Default
    end

    property "versioning strategy when configured correctly" do
      check all versioning <- atom() do
        put_config(:versioning, versioning)
        assert Config.versioning() == versioning
      end
    end

    property "fails when is invalid" do
      check all versioning <- term_except(&is_atom/1) do
        put_config(:versioning, versioning)
        assert_raise RuntimeError, &Config.versioning/0
      end
    end
  end

  describe "verbose?/0" do
    test "true when not configured" do
      delete_config(:verbose)
      assert Config.verbose?()
    end

    property "value when configured correctly" do
      check all verbose? <- boolean() do
        put_config(:verbose, verbose?)
        assert Config.verbose?() == verbose?
      end
    end

    property "fails when is invalid" do
      check all verbose? <- term_except(&is_boolean/1) do
        put_config(:verbose, verbose?)
        assert_raise RuntimeError, &Config.verbose?/0
      end
    end
  end

  @min_wait 100

  describe "wait/0" do
    property "default wait when not configured" do
      check all key <- waits() |> member_of() do
        delete_config(:waits)
        assert Config.wait(key) > @min_wait
      end
    end

    property "defined wait when configured" do
      check all key <- waits() |> member_of(),
                wait <- positive_integer() do
        put_config(:waits, [{key, wait}])
        assert Config.wait(key) == wait
      end
    end

    property "fails when is invalid" do
      check all key <- waits() |> member_of(),
                wait <- term_except(&(is_integer(&1) and &1 > 0)) do
        put_config(:waits, [{key, wait}])
        assert catch_error(Config.wait(key))
      end
    end
  end

  describe "__application_handler__/0" do
    test "Application when not configured" do
      delete_config(:__application_handler__)
      assert Config.__application_handler__() == Application
    end

    property "value when configured correctly" do
      check all application <- atom() do
        put_config(:__application_handler__, application)
        assert Config.__application_handler__() == application
      end
    end

    property "fails when is invalid" do
      check all application <- term_except(&is_atom/1) do
        put_config(:__application_handler__, application)
        assert_raise RuntimeError, &Config.__application_handler__/0
      end
    end
  end

  describe "__code_handler__/0" do
    test "Code when not configured" do
      delete_config(:__code_handler__)
      assert Config.__code_handler__() == Code
    end

    property "value when configured correctly" do
      check all code <- atom() do
        put_config(:__code_handler__, code)
        assert Config.__code_handler__() == code
      end
    end

    property "fails when is invalid" do
      check all code <- term_except(&is_atom/1) do
        put_config(:__code_handler__, code)
        assert_raise RuntimeError, &Config.__code_handler__/0
      end
    end
  end

  describe "__file_handler__/0" do
    test "File when not configured" do
      delete_config(:__file_handler__)
      assert Config.__file_handler__() == File
    end

    property "value when configured correctly" do
      check all file <- atom() do
        put_config(:__file_handler__, file)
        assert Config.__file_handler__() == file
      end
    end

    property "fails when is invalid" do
      check all file <- term_except(&is_atom/1) do
        put_config(:__file_handler__, file)
        assert_raise RuntimeError, &Config.__file_handler__/0
      end
    end
  end

  describe "__system_handler__/0" do
    test "System when not configured" do
      delete_config(:__system_handler__)
      assert Config.__system_handler__() == System
    end

    property "value when configured correctly" do
      check all system <- atom() do
        put_config(:__system_handler__, system)
        assert Config.__system_handler__() == system
      end
    end

    property "fails when is invalid" do
      check all system <- term_except(&is_atom/1) do
        put_config(:__system_handler__, system)
        assert_raise RuntimeError, &Config.__system_handler__/0
      end
    end
  end

  describe "get/1" do
    property "deli application value for key when set" do
      check all key <- atom(),
                value <- term() do
        put_config(key, value)
        assert Config.get(key) == value
      end
    end

    property "nil when there's no value set" do
      check all key <- atom() do
        delete_config(key)
        assert Config.get(key) == nil
      end
    end
  end

  describe "get/2" do
    property "deli application value for key when set" do
      check all key <- atom(),
                value <- term(),
                default <- term() do
        put_config(key, value)
        assert Config.get(key, default) == value
      end
    end

    property "nil when there's no value set" do
      check all key <- atom(),
                default <- term() do
        delete_config(key)
        assert Config.get(key, default) == default
      end
    end
  end

  describe "fetch!/1" do
    property "deli application value for key when set" do
      check all key <- atom(),
                value <- term() do
        put_config(key, value)
        assert Config.fetch!(key) == value
      end
    end

    property "fails when there's no value set" do
      check all key <- atom() do
        delete_config(key)
        assert_raise ArgumentError, fn -> Config.fetch!(key) end
      end
    end
  end

  describe "mix_env/1" do
    test "makes production be prod" do
      assert Config.mix_env(:production) == :prod
      assert Config.mix_env("production") == :prod
    end

    property "makes nil be default target" do
      check all env <- env() do
        put_config(:default_target, env)
        assert Config.mix_env(nil) == env
        assert Config.mix_env("nil") == env
      end
    end

    property "env when configured as atom" do
      check all env <- strict_atom() do
        assert Config.mix_env(env) == env
      end
    end

    property "to_atom when configured as binary" do
      check all env <- strict_atom() do
        assert Config.mix_env(to_string(env)) == env
      end
    end
  end

  describe "edeliver_target/1" do
    test "makes prod be production" do
      assert Config.edeliver_target(:prod) == "production"
      assert Config.edeliver_target("prod") == "production"
    end

    property "binary when configured as atom" do
      check all target <- binary() do
        assert Config.edeliver_target(target) == target
      end
    end

    property "to_string when configured as binary" do
      check all target <- atom() do
        assert Config.edeliver_target(target) == to_string(target)
      end
    end
  end

  describe "project/0..1" do
    test "uses mix project by default" do
      assert Config.project()[:app] == :deli
      assert Config.project(nil)[:app] == :deli
    end

    property "accepts mix_project as argument" do
      check all project <- term(),
                mix_project = %{project: project} do
        assert Config.project(mix_project) == project
      end
    end
  end

  describe "version/0..1" do
    test "uses mix project's version by default" do
      check = &String.starts_with?(to_string(&1), "0.2")
      assert check.(Config.version())
      assert check.(Config.version(nil))
    end

    property "accepts mix_project as argument" do
      check all version <- version(),
                mix_project = %{project: [version: version]} do
        assert to_string(Config.version(mix_project)) == version
      end
    end
  end
end
