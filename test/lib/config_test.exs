defmodule Deli.ConfigTest do
  use ExUnit.Case
  import ExUnitProperties
  alias Deli.Config

  def put_config(key, value) do
    :ok = :deli |> Application.put_env(key, value)
  end

  def delete_config(key) do
    :ok = :deli |> Application.delete_env(key)
  end

  describe "app/0" do
    test "uses mix project app when app not configured" do
      delete_config(:app)
      assert Config.app() == :deli
    end

    test "returns app configured when atom" do
      check all a <- :alphanumeric |> StreamData.atom() do
        put_config(:app, a)
        assert Config.app() == a
      end
    end

    test "fails when app configured but not an atom" do
      put_config(:app, "not_an_atom")
      assert_raise RuntimeError, &Config.app/0
    end
  end

  describe "app_user/1" do
    test "fails if `env` is not an atom" do
      call = fn -> Config.app_user("staging") end
      assert_raise FunctionClauseError, call
    end

    test "returns app when not configured" do
      check all a <- :alphanumeric |> StreamData.atom() do
        put_config(:app, a)
        delete_config(:app_user)
        assert Config.app_user(:staging) == a
        assert Config.app_user(:prod) == a
      end
    end

    test "returns app_user configured when atom" do
      check all a <- :alphanumeric |> StreamData.atom() do
        put_config(:app_user, a)
        assert Config.app_user(:staging) == a
        assert Config.app_user(:prod) == a
      end
    end

    test "returns app_user configured when binary" do
      check all a <- StreamData.binary() do
        put_config(:app_user, a)
        assert Config.app_user(:staging) == a
        assert Config.app_user(:prod) == a
      end
    end

    test "returns env specific user when configured as such" do
      check all s <- :alphanumeric |> StreamData.atom(),
                p <- :alphanumeric |> StreamData.atom() do
        put_config(:app_user, staging: s, prod: p)
        assert Config.app_user(:staging) == s
        assert Config.app_user(:prod) == p
      end
    end

    test "fails when app_user is configured as something else" do
      call = fn -> Config.app_user(:staging) end
      put_config(:app_user, 123)
      assert_raise CaseClauseError, call
    end
  end

  describe "assets?/0" do
    test "returns false when not configured" do
      delete_config(:assets)
      assert Config.assets?() == false
    end

    test "returns boolean when configured as boolean" do
      check all a <- StreamData.boolean() do
        put_config(:assets, a)
        assert Config.assets?() == a
      end
    end

    test "fails when configured as something else" do
      put_config(:assets, :not_a_boolean)
      assert_raise RuntimeError, &Config.assets?/0
    end
  end

  describe "cookie/0" do
    test "returns app when not configured" do
      delete_config(:app)
      delete_config(:cookie)
      assert Config.cookie() == @default_app
    end

    test "returns cookie when configured as atom" do
      check all a <- :alphanumeric |> StreamData.atom() do
        put_config(:cookie, a)
        assert Config.cookie() == a
      end
    end

    test "fails when configured as something else" do
      not_an_atom = StreamData.term() |> Stream.filter(&(not is_atom(&1)))

      check all a <- not_an_atom do
        put_config(:cookie, a)
        assert_raise RuntimeError, &Config.cookie/0
      end
    end
  end
end
