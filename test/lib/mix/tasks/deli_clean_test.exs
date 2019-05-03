defmodule Mix.DeliCleanTest do
  use DeliCase
  alias Mix.Tasks.Deli.Clean

  @clean_paths ~w(
    .deliver/config
    .deli/Dockerfile
    .deli/docker-compose.yml
  )

  setup do
    put_config(:__system_handler__, SystemStub)
    put_config(:__file_handler__, FileStub)
  end

  def cmd_call(command, args) do
    {:__system_handler__, :cmd, command, args, into: ""}
  end

  test "cleans releases dir" do
    :ok = Clean.run([])
    call = cmd_call("rm", ["-rf", "/home/deli/.deli/releases"])
    assert_received ^call
  end

  property "removes files autogenerated by deli" do
    check all autogenerated? <- boolean(),
              prefix <- string(),
              suffix <- string(),
              path <- member_of(@clean_paths) do
      path = "/home/deli/#{path}"

      content =
        if autogenerated? do
          prefix <> "autogenerated by deli" <> suffix
        else
          prefix <> suffix
        end

      :ok =
        TestAgent.set(:read!, fn
          ^path -> content
          _ -> ""
        end)

      removal = cmd_call("rm", [path])

      :ok = Clean.run([])

      if autogenerated? do
        assert_received ^removal
      else
        refute_received ^removal
      end
    end
  end
end
