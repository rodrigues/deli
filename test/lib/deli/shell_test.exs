defmodule Deli.ShellTest do
  use DeliCase
  alias Deli.Shell

  setup do
    put_config(:__system__, SystemStub)
    put_config(:__file_handler__, FileStub)
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
                args <- nonempty_string() |> list_of() do
        command = a |> to_string
        :ok = a |> Shell.cmd(args)
        assert_received {:__system__, :cmd, ^command, ^args, _}
      end
    end

    property "optionally outputs command call" do
      put_config(:output_commands, true)

      check all command <- nonempty_string(),
                args <- nonempty_string() |> list_of() |> nonempty() do
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

      check all command <- nonempty_string(),
                args <- nonempty_string() |> list_of() do
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
      check all command <- nonempty_string(),
                args <- nonempty_string() |> list_of() do
        :ok = command |> Shell.cmd(args)

        assert_received {:__system__, :cmd, ^command, ^args, into: ""}
      end
    end

    property "ok when signal is in ok_signals" do
      check all command <- nonempty_string(),
                args <- nonempty_string() |> list_of(),
                ok_signals <- 0..999 |> integer() |> list_of() |> nonempty(),
                [signal] = ok_signals |> Enum.take_random(1) do
        stub_cmd({"", signal})
        assert :ok == Shell.cmd(command, args, ok_signals)
      end
    end

    property "fails when signal not in ok_signals" do
      check all command <- nonempty_string(),
                args <- nonempty_string() |> list_of(),
                ok_signals <- 0..999 |> integer() |> list_of() |> nonempty(),
                signal <- 0..999 |> integer(),
                not Enum.member?(ok_signals, signal) do
        stub_cmd({"", signal})

        call = fn ->
          capture_io(fn ->
            Shell.cmd(command, args, ok_signals)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}
      end
    end

    property "propagates opts downstream" do
      check all command <- nonempty_string(),
                args <- nonempty_string() |> list_of(),
                opts <- term() |> keyword_of(),
                ok_signals <- 0..999 |> integer() |> list_of() |> nonempty(),
                [signal] = ok_signals |> Enum.take_random(1) do
        stub_cmd({"", signal})
        :ok = command |> Shell.cmd(args, ok_signals, opts)
        expected_opts = [into: ""] ++ opts
        assert_received {:__system__, :cmd, ^command, ^args, ^expected_opts}
      end
    end
  end

  describe "cmd_result/2..4" do
    property "returns tuple with result of cmd" do
      check all command <- nonempty_string(),
                args <- nonempty_string() |> list_of(),
                opts <- term() |> keyword_of(),
                ok_signals <- 0..999 |> integer() |> list_of() |> nonempty(),
                result <- binary(),
                [signal] = ok_signals |> Enum.take_random(1) do
        stub_cmd({result, signal})
        {:ok, ^result} = command |> Shell.cmd_result(args, ok_signals, opts)
        expected_opts = [into: ""] ++ opts
        assert_received {:__system__, :cmd, ^command, ^args, ^expected_opts}
      end
    end
  end

  describe "edeliver/1..2" do
    property "calls edeliver with no args" do
      check all command <- nonempty_string() do
        stub_cmd({"", 0})
        :ok = command |> Shell.edeliver()
        expected_opts = [into: ""]

        assert_received {
          :__system__,
          :cmd,
          "mix",
          ["edeliver", ^command],
          ^expected_opts
        }
      end
    end

    property "calls edeliver with args" do
      check all command <- nonempty_string(),
                args <- nonempty_string() |> list_of() do
        stub_cmd({"", 0})
        :ok = command |> Shell.edeliver(args)
        expected_opts = [into: ""]

        assert_received {
          :__system__,
          :cmd,
          "mix",
          ["edeliver", ^command | ^args],
          ^expected_opts
        }
      end
    end

    property "fails on a signal different than 0" do
      check all command <- nonempty_string(),
                args <- nonempty_string() |> list_of(),
                signal <- 1..999 |> integer() do
        stub_cmd({"", signal})

        call = fn ->
          capture_io(fn ->
            Shell.edeliver(command, args)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}
      end
    end

    property "propagates verbose downstream" do
      check all command <- nonempty_string(),
                args <- nonempty_string() |> list_of() do
        put_config(:verbose, true)
        stub_cmd({"", 0})

        expected_opts = [
          into: %IO.Stream{device: :standard_io, line_or_bytes: :line, raw: false},
          stderr_to_stdout: true
        ]

        expected_args = ["edeliver", command] ++ args ++ ["--verbose"]

        :ok = command |> Shell.edeliver(args)

        assert_received {
          :__system__,
          :cmd,
          "mix",
          ^expected_args,
          ^expected_opts
        }
      end
    end
  end

  describe "docker_compose/1..3" do
    property "calls docker_compose with no args" do
      check all command <- nonempty_string() do
        stub_cmd({"", 0})
        :ok = command |> Shell.docker_compose()
        expected_opts = [into: "", env: [{"COMPOSE_INTERACTIVE_NO_CLI", "1"}]]

        assert_received {
          :__system__,
          :cmd,
          "docker-compose",
          ["-f", ".deli/docker-compose.yml", ^command],
          ^expected_opts
        }
      end
    end

    property "calls docker_compose with args" do
      check all command <- nonempty_string(),
                args <- nonempty_string() |> list_of() do
        stub_cmd({"", 0})
        :ok = command |> Shell.docker_compose(args)
        expected_opts = [into: "", env: [{"COMPOSE_INTERACTIVE_NO_CLI", "1"}]]

        assert_received {
          :__system__,
          :cmd,
          "docker-compose",
          ["-f", ".deli/docker-compose.yml", ^command | ^args],
          ^expected_opts
        }
      end
    end

    property "fails on a signal different than 0" do
      check all command <- nonempty_string(),
                args <- nonempty_string() |> list_of(),
                signal <- 1..999 |> integer() do
        stub_cmd({"", signal})

        call = fn ->
          capture_io(fn ->
            Shell.docker_compose(command, args)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}
      end
    end

    property "ok on a signal in ok_signals" do
      check all command <- nonempty_string(),
                args <- nonempty_string() |> list_of(),
                ok_signals <- 0..999 |> integer() |> list_of() |> nonempty(),
                [signal] = ok_signals |> Enum.take_random(1) do
        stub_cmd({"", signal})

        assert Shell.docker_compose(command, args, ok_signals) == :ok
      end
    end

    property "fail on a signal not in ok_signals" do
      check all command <- nonempty_string(),
                args <- nonempty_string() |> list_of(),
                ok_signals <- 0..999 |> integer() |> list_of() |> nonempty(),
                signal <- 0..999 |> integer(),
                not Enum.member?(ok_signals, signal) do
        stub_cmd({"", signal})

        call = fn ->
          capture_io(fn ->
            Shell.docker_compose(command, args, ok_signals)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}
      end
    end
  end

  describe "file_exists?/1" do
    property "whether file exists or not in app project" do
      check all path <- nonempty_string(),
                cwd <- ?a..?z |> nonempty_string(),
                exists? <- boolean() do
        cwd = "/tmp/deli/#{cwd}"
        expanded = "#{cwd}/#{path}"
        :ok = :cwd! |> TestAgent.set(fn -> cwd end)
        :ok = :exists? |> TestAgent.set(fn ^expanded -> exists? end)

        assert Shell.file_exists?(path) == exists?
      end
    end
  end

  describe "write_file/2..3" do
    property "writes content into file" do
      check all path <- nonempty_string(),
                cwd <- ?a..?z |> nonempty_string(),
                content <- binary(),
                result <- term() do
        cwd = "/tmp/deli/#{cwd}"
        expanded = "#{cwd}/#{path}"
        :ok = :cwd! |> TestAgent.set(fn -> cwd end)
        :ok = :write! |> TestAgent.set(fn ^expanded, ^content -> result end)

        ^result = path |> Shell.write_file(content)

        assert_received {:__file_handler__, :write!, ^expanded, ^content, []}
      end
    end

    property "writes content into file with options" do
      check all path <- nonempty_string(),
                cwd <- ?a..?z |> nonempty_string(),
                content <- binary(),
                opts <- atom() |> list_of() |> nonempty(),
                result <- term() do
        cwd = "/tmp/deli/#{cwd}"
        expanded = "#{cwd}/#{path}"
        :ok = :cwd! |> TestAgent.set(fn -> cwd end)
        :ok = :write! |> TestAgent.set(fn ^expanded, ^content -> result end)

        ^result = path |> Shell.write_file(content, opts)

        assert_received {:__file_handler__, :write!, ^expanded, ^content, ^opts}
      end
    end
  end

  describe "confirm?/2" do
    property "autoconfirms if yes passed as opt" do
      check all app <- atom(),
                target <- atom(),
                operation <- atom(),
                opts <- term() |> keyword_of() do
        opts =
          opts
          |> Keyword.put(:target, target)
          |> Keyword.put(:yes, true)

        put_config(:app, app)

        output =
          capture_io(fn ->
            true = operation |> Shell.confirm?(opts)
          end)

        assert output == "#{operation} #{app} at #{target}? [Yn] y\n"
      end
    end

    property "asks user confirmation if yes not passed as opt" do
      check all app <- atom(),
                target <- atom(),
                operation <- atom(),
                opts <- term() |> keyword_of(),
                confirms? <- boolean() do
        opts =
          opts
          |> Keyword.put(:target, target)

        put_config(:app, app)

        input = if confirms?, do: "\n", else: "n\n"

        output =
          capture_io([input: input, capture_prompt: true], fn ->
            ^confirms? = operation |> Shell.confirm?(opts)
          end)

        assert output == "#{operation} #{app} at #{target}? [Yn] "
      end
    end

    property "fails when target is not provided" do
      check all app <- atom(),
                operation <- atom(),
                opts <- term() |> keyword_of(),
                not Keyword.has_key?(opts, :target) do
        put_config(:app, app)

        assert_raise KeyError, fn -> Shell.confirm?(operation, opts) end
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
