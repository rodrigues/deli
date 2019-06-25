defmodule Deli.BeamVersionsTest do
  use DeliCase, async: true
  alias Deli.BeamVersions

  describe "deps/0" do
    test "has beam dependencies" do
      deps = BeamVersions.deps()
      assert Enum.member?(deps, :otp)
      assert Enum.member?(deps, :elixir)
      assert Enum.member?(deps, :rebar3)
    end
  end

  describe "versions/0" do
    test "has versions for beam dependencies" do
      [{version, checksum} | _] = BeamVersions.versions()[:otp]

      assert is_binary(version)
      assert is_binary(checksum)
    end
  end

  describe "fetch/0..1" do
    def assert_versions(versions) do
      for {dep, version: version, checksum: sum} <- versions do
        assert is_atom(dep)
        assert is_binary(version)
        assert is_binary(sum)
      end
    end

    test "brings fresh set of beam dependencies without opts" do
      versions = BeamVersions.fetch()
      assert Enum.count(versions) >= 3
      assert_versions(versions)
    end

    test "keeps user set of beam dependencies when existing" do
      opts = [otp: "21.0"]
      versions = BeamVersions.fetch(opts)
      assert Enum.count(versions) >= 3
      assert_versions(versions)
      assert versions[:otp][:version] == "21.0"
    end

    test "fails when user passes unexisting version" do
      opts = [otp: "2001"]
      call = fn -> BeamVersions.fetch(opts) end
      assert_raise RuntimeError, call
    end
  end
end
