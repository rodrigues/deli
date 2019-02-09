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
end
