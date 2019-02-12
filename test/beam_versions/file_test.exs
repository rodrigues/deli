defmodule Deli.BeamVersions.FileTest do
  use DeliCase
  alias Deli.BeamVersions.File

  @path "lib/deli/beam_versions/data.exs"

  setup do
    put_config(:__file_handler__, FileStub)
    put_config(:__code_handler__, CodeStub)
  end

  describe "versions_from_file/0..1" do
    property "persisted versions" do
      check all versions <-
                  map_of(
                    atom(),
                    list_of(tuple({non_empty_string(), non_empty_string()}), max_length: 5),
                    max_length: 5
                  ) do
        :ok = :eval_file |> TestAgent.set(fn @path -> {versions, []} end)
        assert File.versions_from_file() == versions
      end
    end

    property "adds empty list to new keys passed in args" do
      check all key_b <- atom(),
                versions <-
                  map_of(
                    atom(),
                    list_of(tuple({non_empty_string(), non_empty_string()}), max_length: 5),
                    min_length: 1,
                    max_length: 5
                  ),
                not Map.has_key?(versions, key_b) do
        key_a = versions |> Map.keys() |> Enum.at(0)
        :ok = :eval_file |> TestAgent.set(fn @path -> {versions, []} end)
        result = File.versions_from_file([key_a, key_b])

        assert result[key_a] == versions[key_a]
        assert result[key_b] == []

        for {key, value} <- versions do
          assert result[key] == value
        end
      end
    end
  end

  describe "persist_versions/1" do
    property "writes formatted versions" do
      check all versions <-
                  map_of(
                    atom(),
                    list_of(tuple({non_empty_string(), non_empty_string()}), max_length: 5),
                    min_length: 1,
                    max_length: 5
                  ) do
        :ok = versions |> File.persist_versions()
        content = inspect(versions)

        assert_received {:__code_handler__, :format_string!, ^content}
        assert_received {:__file_handler__, :write!, @path, ^content}
      end
    end
  end
end
