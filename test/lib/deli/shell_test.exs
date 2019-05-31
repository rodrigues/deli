defmodule Deli.ShellTest do
  use DeliCase, async: true
  alias Deli.Shell

  setup do
    put_config(:__application_handler__, ApplicationStub)
    put_config(:__file_handler__, FileStub)
    put_config(:__system_handler__, SystemStub)
  end

  @ok_range 0..999
  def ok_signals, do: @ok_range |> integer() |> list_of() |> nonempty()
  def ok_signal, do: integer(@ok_range)
  def ok_signal(signals), do: signals |> Enum.take_random(1) |> Enum.at(0)

  describe "cmd/1..4" do
    property "runs shell command without args as atom" do
      check all cmd <- atom() do
        :ok = Shell.cmd(cmd)
        cmd = to_string(cmd)
        assert_received {:__system_handler__, :cmd, ^cmd, [], _}
      end
    end

    property "runs shell command without args as binary" do
      check all cmd <- cmd() do
        :ok = Shell.cmd(cmd)
        assert_received {:__system_handler__, :cmd, ^cmd, [], _}
      end
    end

    property "accepts args" do
      check all {cmd, args} <- cmd_with_args() do
        :ok = Shell.cmd(cmd, args)
        assert_received {:__system_handler__, :cmd, ^cmd, ^args, _}
      end
    end

    property "optionally outputs command call" do
      put_config(:output_commands, true)

      check all cmd <- cmd(),
                args <- nonempty_string() |> list_of() |> nonempty() do
        output =
          capture_io(fn ->
            :ok = Shell.cmd(cmd, args)
          end)

        argv = Enum.join(args, " ")

        assert output == "\e[1m$ \e[0m\e[4m#{cmd} #{argv}\e[0m\n"
        assert_received {:__system_handler__, :cmd, ^cmd, ^args, _}
      end
    end

    property "outputs command output when verbose" do
      put_config(:verbose, true)

      check all {cmd, args} <- cmd_with_args() do
        :ok = Shell.cmd(cmd, args)

        assert_received {
          :__system_handler__,
          :cmd,
          ^cmd,
          ^args,
          into: %IO.Stream{device: :standard_io, line_or_bytes: :line, raw: false},
          stderr_to_stdout: true
        }
      end
    end

    property "does not output command output when not verbose" do
      check all {cmd, args} <- cmd_with_args() do
        :ok = Shell.cmd(cmd, args)

        assert_received {:__system_handler__, :cmd, ^cmd, ^args, into: ""}
      end
    end

    property "ok when signal is in ok_signals" do
      check all {cmd, args} <- cmd_with_args(),
                ok_signals <- ok_signals(),
                [signal] = Enum.take_random(ok_signals, 1) do
        stub_cmd({"", signal})
        assert :ok == Shell.cmd(cmd, args, ok_signals)
      end
    end

    property "fails when signal not in ok_signals" do
      check all {cmd, args} <- cmd_with_args(),
                ok_signals <- ok_signals(),
                signal <- ok_signal(),
                not Enum.member?(ok_signals, signal) do
        stub_cmd({"", signal})

        call = fn ->
          capture_io(fn ->
            Shell.cmd(cmd, args, ok_signals)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}
      end
    end

    property "propagates opts downstream" do
      check all {cmd, args} <- cmd_with_args(),
                opts <- keyword_of(term()),
                ok_signals <- ok_signals(),
                signal = ok_signal(ok_signals) do
        stub_cmd({"", signal})
        :ok = Shell.cmd(cmd, args, ok_signals, opts)
        expected_opts = [into: ""] ++ opts
        assert_received {:__system_handler__, :cmd, ^cmd, ^args, ^expected_opts}
      end
    end
  end

  describe "cmd_result/2..4" do
    property "result when succeeds" do
      check all {cmd, args} <- cmd_with_args(),
                opts <- keyword_of(term()),
                result <- nonempty_string(),
                ok_signals <- ok_signals(),
                signal = ok_signal(ok_signals) do
        stub_cmd({result, signal})

        {:ok, ^result} = Shell.cmd_result(cmd, args, ok_signals, opts)

        expected_opts = [into: ""] ++ opts
        assert_received {:__system_handler__, :cmd, ^cmd, ^args, ^expected_opts}
      end
    end

    property "stream when succeeds and result is a stream" do
      check all {cmd, args} <- cmd_with_args(),
                opts <- keyword_of(term()),
                ok_signals <- ok_signals(),
                signal = ok_signal(ok_signals) do
        result = %IO.Stream{device: :standard_io, line_or_bytes: :line, raw: false}
        stub_cmd({result, signal})

        {:ok, ^result} = Shell.cmd_result(cmd, args, ok_signals, opts)

        expected_opts = [into: ""] ++ opts
        assert_received {:__system_handler__, :cmd, ^cmd, ^args, ^expected_opts}
      end
    end
  end

  describe "edeliver/1..2" do
    property "calls edeliver with no args" do
      check all cmd <- nonempty_string() do
        stub_cmd({"", 0})
        :ok = Shell.edeliver(cmd)
        expected_opts = [into: ""]

        assert_received {
          :__system_handler__,
          :cmd,
          "mix",
          ["edeliver", ^cmd],
          ^expected_opts
        }
      end
    end

    property "calls edeliver with args" do
      check all {cmd, args} <- cmd_with_args() do
        stub_cmd({"", 0})
        :ok = Shell.edeliver(cmd, args)
        expected_opts = [into: ""]

        assert_received {
          :__system_handler__,
          :cmd,
          "mix",
          ["edeliver", ^cmd | ^args],
          ^expected_opts
        }
      end
    end

    property "fails on a signal different than 0" do
      check all {cmd, args} <- cmd_with_args(),
                signal <- ok_signal() do
        stub_cmd({"", signal})

        call = fn ->
          capture_io(fn ->
            Shell.edeliver(cmd, args)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}
      end
    end

    property "propagates verbose downstream" do
      check all {cmd, args} <- cmd_with_args() do
        put_config(:verbose, true)
        stub_cmd({"", 0})

        expected_opts = [
          into: %IO.Stream{device: :standard_io, line_or_bytes: :line, raw: false},
          stderr_to_stdout: true
        ]

        expected_args = ["edeliver", cmd] ++ args ++ ["--verbose"]

        :ok = Shell.edeliver(cmd, args)

        assert_received {
          :__system_handler__,
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
      check all cmd <- nonempty_string() do
        stub_cmd({"", 0})
        :ok = Shell.docker_compose(cmd)
        expected_opts = [into: "", env: [{"COMPOSE_INTERACTIVE_NO_CLI", "1"}]]

        assert_received {
          :__system_handler__,
          :cmd,
          "docker-compose",
          ["-f", ".deli/docker-compose.yml", ^cmd],
          ^expected_opts
        }
      end
    end

    property "calls docker_compose with args" do
      check all {cmd, args} <- cmd_with_args() do
        stub_cmd({"", 0})
        :ok = Shell.docker_compose(cmd, args)
        expected_opts = [into: "", env: [{"COMPOSE_INTERACTIVE_NO_CLI", "1"}]]

        assert_received {
          :__system_handler__,
          :cmd,
          "docker-compose",
          ["-f", ".deli/docker-compose.yml", ^cmd | ^args],
          ^expected_opts
        }
      end
    end

    property "fails on a signal different than 0" do
      check all {cmd, args} <- cmd_with_args(),
                signal <- ok_signal(),
                signal != 0 do
        stub_cmd({"", signal})

        call = fn ->
          capture_io(fn ->
            Shell.docker_compose(cmd, args)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}
      end
    end

    property "ok on a signal in ok_signals" do
      check all {cmd, args} <- cmd_with_args(),
                ok_signals <- ok_signals() do
        signal = ok_signal(ok_signals)
        stub_cmd({"", signal})

        assert Shell.docker_compose(cmd, args, ok_signals) == :ok
      end
    end

    property "fail on a signal not in ok_signals" do
      check all {cmd, args} <- cmd_with_args(),
                ok_signals <- ok_signals(),
                signal <- ok_signal(),
                not Enum.member?(ok_signals, signal) do
        stub_cmd({"", signal})

        call = fn ->
          capture_io(fn ->
            Shell.docker_compose(cmd, args, ok_signals)
          end)
        end

        assert catch_exit(call.()) == {:shutdown, signal}
      end
    end
  end

  describe "file_exists?/1" do
    property "whether file exists or not in app project" do
      check all path <- nonempty_string(),
                cwd <- nonempty_string(?a..?z),
                exists? <- boolean() do
        cwd = "/tmp/deli/#{cwd}"
        expanded = "#{cwd}/#{path}"
        :ok = TestAgent.set(:cwd!, fn -> cwd end)
        :ok = TestAgent.set(:exists?, fn ^expanded -> exists? end)

        assert Shell.file_exists?(path) == exists?
      end
    end
  end

  describe "write_file/2..3" do
    property "writes content into file" do
      check all path <- nonempty_string(),
                cwd <- nonempty_string(?a..?z),
                content <- binary(),
                result <- term() do
        cwd = "/tmp/deli/#{cwd}"
        expanded = "#{cwd}/#{path}"
        :ok = TestAgent.set(:cwd!, fn -> cwd end)
        :ok = TestAgent.set(:write!, fn ^expanded, ^content -> result end)

        ^result = Shell.write_file(path, content)

        assert_received {:__file_handler__, :write!, ^expanded, ^content, []}
      end
    end

    property "writes content into file with options" do
      check all path <- nonempty_string(),
                cwd <- nonempty_string(?a..?z),
                content <- binary(),
                opts <- atom() |> list_of() |> nonempty(),
                result <- term() do
        cwd = "/tmp/deli/#{cwd}"
        expanded = "#{cwd}/#{path}"
        :ok = TestAgent.set(:cwd!, fn -> cwd end)
        :ok = TestAgent.set(:write!, fn ^expanded, ^content -> result end)

        ^result = Shell.write_file(path, content, opts)

        assert_received {:__file_handler__, :write!, ^expanded, ^content, ^opts}
      end
    end
  end

  describe "confirm?/2" do
    property "autoconfirms if yes passed as opt" do
      check all app <- app(),
                target <- atom(),
                operation <- atom(),
                opts <- keyword_of(term()) do
        opts =
          opts
          |> Keyword.put(:target, target)
          |> Keyword.put(:yes, true)

        put_config(:app, app)

        output =
          capture_io(fn ->
            true = Shell.confirm?(operation, opts)
          end)

        assert output == "#{operation} #{app} at #{target}? [Yn] y\n"
      end
    end

    property "asks user confirmation if yes not passed as opt" do
      check all app <- app(),
                target <- atom(),
                operation <- atom(),
                opts <- keyword_of(term()),
                confirms? <- boolean() do
        opts = Keyword.put(opts, :target, target)

        put_config(:app, app)

        input = if confirms?, do: "\n", else: "n\n"

        output =
          capture_io([input: input, capture_prompt: true], fn ->
            ^confirms? = Shell.confirm?(operation, opts)
          end)

        assert output == "#{operation} #{app} at #{target}? [Yn] "
      end
    end

    property "fails when target is not provided" do
      check all app <- app(),
                operation <- atom(),
                opts <- keyword_of(term()),
                not Keyword.has_key?(opts, :target) do
        put_config(:app, app)

        assert_raise KeyError, fn -> Shell.confirm?(operation, opts) end
      end
    end
  end

  describe "cancelled!/1" do
    property "prints operation was cancelled by user" do
      check all operation <- atom() do
        output = capture_io(fn -> Shell.cancelled!(operation) end)
        assert output == "\e[32m#{operation} cancelled by user\e[0m\n"
      end
    end
  end

  describe "ensure_all_started/1" do
    property "ensures application and dependencies started" do
      check all app <- app() do
        {:ok, [^app]} = Shell.ensure_all_started(app)

        assert_received {
          :__application_handler__,
          :ensure_all_started,
          ^app
        }
      end
    end
  end

  describe "parse_options/1" do
    property "user target when valid" do
      chars = [?_ | Enum.to_list(?a..?z)]

      check all target <- nonempty_string(chars),
                short? <- boolean() do
        flag = if short?, do: "-t", else: "--target"
        opts = [flag, target]
        parsed_opts = Shell.parse_options(opts)

        assert parsed_opts[:target] == String.to_atom(target)
      end
    end

    property "default target when not provided" do
      check all env <- env() do
        put_config(:default_target, env)
        parsed_opts = Shell.parse_options([])

        assert parsed_opts[:target] == env
      end
    end

    property "yes when passed" do
      check all short? <- boolean() do
        flag = if short?, do: "-y", else: "--yes"
        parsed_opts = Shell.parse_options([flag])

        assert parsed_opts[:yes]
      end
    end

    property "assets when passed" do
      check all short? <- boolean() do
        flag = if short?, do: "-a", else: "--assets"
        parsed_opts = Shell.parse_options([flag])

        assert parsed_opts[:assets]
      end
    end

    property "versions when passed" do
      check all short? <- boolean(),
                version <- nonempty_string() do
        flag = if short?, do: "-v", else: "--version"
        parsed_opts = Shell.parse_options([flag, version])

        assert parsed_opts[:version] == version
      end
    end
  end
end
