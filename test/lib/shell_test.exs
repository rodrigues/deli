defmodule Deli.ShellTest do
  use DeliCase
  alias Deli.Shell

  setup do
    put_config(:__system__, SystemStub)
  end

  describe "cmd/1..4" do
    property "runs shell command without args as atom" do
      check all a <- atom() do
        :ok = a |> Shell.cmd()
        command = a |> to_string
        assert_received {:__system__, :cmd, ^command, [], _}
      end
    end

    property "runs shell command without args as binary" do
      check all a <- string() do
        :ok = a |> Shell.cmd()
        assert_received {:__system__, :cmd, ^a, [], _}
      end
    end

    property "accepts args" do
      check all a <- atom(),
                args <- non_empty_string() |> list_of() do
        command = a |> to_string
        :ok = a |> Shell.cmd(args)
        assert_received {:__system__, :cmd, ^command, ^args, _}
      end
    end

    property "optionally outputs command call" do
      put_config(:output_commands, true)

      check all command <- non_empty_string(),
                args <- non_empty_string() |> non_empty_list_of() do
        output =
          capture_io(fn ->
            :ok = command |> Shell.cmd(args)
          end)

        argv = args |> Enum.join(" ")

        assert output == "\e[1m$ \e[0m\e[4m#{command} #{argv}\e[0m\n"
        assert_received {:__system__, :cmd, ^command, ^args, _}
      end
    end

    property "outputs command output when verbose" do
      put_config(:verbose, true)

      check all command <- non_empty_string(),
                args <- non_empty_string() |> non_empty_list_of() do
        :ok = command |> Shell.cmd(args)

        assert_received {
          :__system__,
          :cmd,
          ^command,
          ^args,
          into: %IO.Stream{device: :standard_io, line_or_bytes: :line, raw: false},
          stderr_to_stdout: true
        }
      end
    end

    property "does not output command output when not verbose" do
      check all command <- non_empty_string(),
                args <- non_empty_string() |> non_empty_list_of() do
        :ok = command |> Shell.cmd(args)

        assert_received {:__system__, :cmd, ^command, ^args, into: ""}
      end
    end
  end

  describe "cancelled!/1" do
    property "prints operation was cancelled by user" do
      check all a <- atom() do
        output = capture_io(fn -> Shell.cancelled!(a) end)
        assert output == "\e[32m#{a} cancelled by user\e[0m\n"
      end
    end
  end
end
