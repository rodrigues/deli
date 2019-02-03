defmodule Deli.ConfigTest do
  use ExUnit.Case
  alias Deli.Config

  def put_config(key, value) do
    :ok = Application.put_env(:deli, key, value)
  end

  describe "app/0" do
    test "returns deli config app when atom" do
      put_config(:app, :an_atom)
      assert Config.app() == :an_atom
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
