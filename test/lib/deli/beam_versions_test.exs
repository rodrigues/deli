defmodule Deli.BeamVersionsTest do
  use DeliCase
  alias Deli.BeamVersions

  describe "deps/0" do
    test "has beam dependencies" do
      deps = BeamVersions.deps()
      assert deps |> Enum.member?(:otp)
      assert deps |> Enum.member?(:elixir)
      assert deps |> Enum.member?(:rebar3)
    end
  end

  describe "versions/0" do
    test "has versions for beam dependencies" do
      versions = BeamVersions.versions()

      {version, checksum} = versions[:otp] |> Enum.at(0)

      assert is_binary(version)
      assert is_binary(checksum)
    end
  end

  describe "fetch/0..1" do
    test "brings fresh set of beam dependencies without opts" do
      versions = BeamVersions.fetch()
      assert Enum.count(versions) >= 3

      for {dep, version: version, checksum: sum} <- versions do
        assert dep |> is_atom
        assert version |> is_binary
        assert sum |> is_binary
      end
    end

    test "keeps user set of beam dependencies when existing" do
      opts = [otp: "21.0"]
      versions = opts |> BeamVersions.fetch()
      assert Enum.count(versions) >= 3

      assert versions[:otp][:version] == "21.0"

      for {dep, version: version, checksum: sum} <- versions do
        assert dep |> is_atom
        assert version |> is_binary
        assert sum |> is_binary
      end
    end

    test "fails when user passes unexisting version" do
      opts = [otp: "2001"]
      call = fn -> opts |> BeamVersions.fetch() end
      assert_raise RuntimeError, call
    end
  end
end
