defmodule Deli.ConfigTest do
  use ExUnit.Case
  import ExUnitProperties
  alias Deli.Config

  def put_config(key, value) do
    :ok = :deli |> Application.put_env(key, value)
  end

  describe "app/0" do
    test "uses mix project app when app not configured" do
      put_config(:app, nil)
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

    test "uses mix project app when app not configured" do
      put_config(:app, nil)
      assert Config.app() == :deli
    end
  end
end
