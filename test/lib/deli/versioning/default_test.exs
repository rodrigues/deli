defmodule Deli.Versioning.DefaultTest do
  use DeliCase
  alias Deli.Versioning.Default, as: Versioning

  setup do
    put_config(:__system_handler__, SystemStub)
  end

  test "behaviour" do
    assert behaves?(Versioning, Deli.Versioning)
  end

  describe "version_tag/1" do
    property "returns version tag when informed" do
      check all version <- version(),
                prefix? <- boolean() do
        informed_version = if prefix?, do: "v#{version}", else: version
        {:ok, sanitized_version} = Versioning.version_tag(informed_version)

        assert sanitized_version == "v#{version}"

        refute_received _
      end
    end

    test "when not informed, fails when version lower than latest git tag" do
      git_tag = "100.0.1"

      pid = self()

      :ok =
        TestAgent.set(:cmd, fn
          "git", ~w(fetch --tags), into: "" ->
            send(pid, :git_fetch_tags)
            {"", 0}

          "git", ~w(tag -l --sort version:refname), into: "" ->
            send(pid, :git_tag_list)
            {"\n\nv#{git_tag}\n\n", 0}
        end)

      call = fn ->
        capture_io(:stderr, fn ->
          Versioning.version_tag(nil)
        end)
      end

      assert catch_exit(call.()) == {:shutdown, 1}

      assert_received :git_fetch_tags
      assert_received :git_tag_list
    end

    test "when not informed, fails when version is latest git tag with different sha" do
      version = Deli.MixProject.project()[:version]
      version_tag = "v#{version}"
      head_sha = "a"
      version_sha = "b"

      pid = self()

      :ok =
        TestAgent.set(:cmd, fn
          "git", ~w(fetch --tags), into: "" ->
            send(pid, :git_fetch_tags)
            {"", 0}

          "git", ~w(tag -l --sort version:refname), into: "" ->
            send(pid, :git_tag_list)
            {"\n\n#{version_tag}\n\n", 0}

          "git", ~w(rev-list -n 1 HEAD), into: "" ->
            send(pid, :git_sha_head)
            {head_sha, 0}

          "git", ["rev-list", "-n", "1", ^version_tag], into: "" ->
            send(pid, :git_sha_version)
            {version_sha, 0}
        end)

      call = fn ->
        capture_io(:stderr, fn ->
          Versioning.version_tag(nil)
        end)
      end

      assert catch_exit(call.()) == {:shutdown, 1}

      assert_received :git_fetch_tags
      assert_received :git_tag_list
      assert_received :git_sha_head
      assert_received :git_sha_version
    end

    test "when not informed, creates when version is latest git tag with same sha" do
      version = Deli.MixProject.project()[:version]
      version_tag = "v#{version}"
      sha = "foo"

      pid = self()

      :ok =
        TestAgent.set(:cmd, fn
          "git", ~w(fetch --tags), into: "" ->
            send(pid, :git_fetch_tags)
            {"", 0}

          "git", ~w(tag -l --sort version:refname), into: "" ->
            send(pid, :git_tag_list)
            {"\n\n#{version_tag}\n\n", 0}

          "git", ~w(rev-list -n 1 HEAD), into: "" ->
            send(pid, :git_sha_head)
            {sha, 0}

          "git", ["rev-list", "-n", "1", ^version_tag], into: "" ->
            send(pid, :git_sha_version)
            {sha, 0}
        end)

      output =
        capture_io(fn ->
          {:ok, ^version_tag} = Versioning.version_tag(nil)
        end)

      assert output == ""

      assert_received :git_fetch_tags
      assert_received :git_tag_list
      assert_received :git_sha_head
      assert_received :git_sha_version
    end

    test "when not informed, creates when version bigger than latest git tag" do
      git_tag = "0.0.1"
      version = Deli.MixProject.project()[:version]
      version_tag = "v#{version}"

      pid = self()

      :ok =
        TestAgent.set(:cmd, fn
          "git", ~w(fetch --tags), into: "" ->
            send(pid, :git_fetch_tags)
            {"", 0}

          "git", ~w(tag -l --sort version:refname), into: "" ->
            send(pid, :git_tag_list)
            {"\n\nv#{git_tag}\n\n", 0}

          "git", ["tag", ^version_tag], into: "" ->
            send(pid, :git_tag)
            {"", 0}

          "git", ["push", "origin", ^version_tag], into: "" ->
            send(pid, :git_push_tag)
            {"", 0}
        end)

      output =
        capture_io(fn ->
          {:ok, ^version_tag} = Versioning.version_tag(nil)
        end)

      assert output == ""

      assert_received :git_fetch_tags
      assert_received :git_tag_list
      assert_received :git_tag
      assert_received :git_push_tag
    end
  end
end
