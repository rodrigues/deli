defmodule Deli.HostFilter.DefaultTest do
  use DeliCase
  alias Deli.HostFilter.Default, as: HostFilter

  test "behaviour" do
    assert behaves?(HostFilter, Deli.HostFilter)
  end

  describe "hosts/2" do
    property "all hosts when not filtering" do
      check all env <- env(),
                h1 <- host(),
                h2 <- host() do
        h3 = h1 <> h2

        HostProviderMock
        |> expect(:hosts, fn ^env -> [h1, h2, h3] end)

        output =
          capture_io(fn ->
            {:ok, [^h1, ^h2, ^h3]} = env |> HostFilter.hosts([])
          end)

        assert output == "# hosts\n## #{h1}\n## #{h2}\n## #{h3}\n"
      end
    end

    property "filters hosts" do
      check all env <- env(),
                h1 <- ?a..?k |> nonempty_string(),
                h2 <- ?l..?z |> nonempty_string(),
                term_size <- 1..5 |> integer() do
        h3 = h1 <> h2

        HostProviderMock
        |> expect(:hosts, fn ^env -> [h1, h2, h3] end)

        {filter, _} = h1 |> String.split_at(term_size)

        output =
          capture_io(fn ->
            {:ok, [^h1, ^h3]} = env |> HostFilter.hosts(["-h", filter])
          end)

        assert output == "# hosts\n## #{h1}\n## #{h3}\n"
      end
    end

    property "fails if all hosts are excluded after filter" do
      check all env <- env(),
                h1 <- ?a..?k |> nonempty_string(),
                h2 <- ?l..?z |> nonempty_string(),
                filter <- ?0..?9 |> nonempty_string() do
        h3 = h1 <> h2

        HostProviderMock
        |> expect(:hosts, fn ^env -> [h1, h2, h3] end)

        call = fn ->
          capture_io(:stderr, fn ->
            HostFilter.hosts(env, ["-h", filter])
          end)
        end

        assert catch_exit(call.()) == {:shutdown, 1}
      end
    end

    property "fails if no hosts are defined for env and filtering" do
      check all env <- env(),
                filter <- ?a..?z |> nonempty_string() do
        HostProviderMock
        |> expect(:hosts, fn ^env -> [] end)

        call = fn ->
          capture_io(:stderr, fn ->
            HostFilter.hosts(env, ["-h", filter])
          end)
        end

        assert catch_exit(call.()) == {:shutdown, 1}
      end
    end

    property "fails if no hosts are defined for env and not filtering" do
      check all env <- env() do
        HostProviderMock
        |> expect(:hosts, fn ^env -> [] end)

        call = fn ->
          capture_io(:stderr, fn ->
            HostFilter.hosts(env, [])
          end)
        end

        assert catch_exit(call.()) == {:shutdown, 1}
      end
    end
  end

  describe "host/2" do
    property "host when only one configured and no filter" do
      check all env <- env(),
                h1 <- nonempty_string() do
        HostProviderMock
        |> expect(:hosts, fn ^env -> [h1] end)

        assert {:ok, h1} == env |> HostFilter.host([])
      end
    end

    property "host when only one configured and filter matches" do
      check all env <- env(),
                h1 <- nonempty_string(),
                term_size <- 1..5 |> integer() do
        HostProviderMock
        |> expect(:hosts, fn ^env -> [h1] end)

        {filter, _} = h1 |> String.split_at(term_size)

        assert {:ok, h1} == env |> HostFilter.host(["-h", filter])
      end
    end

    property "error when only one configured and filter doesn't match" do
      check all env <- env(),
                h1 <- ?a..?z |> nonempty_string(),
                filter <- ?0..?9 |> nonempty_string() do
        HostProviderMock
        |> expect(:hosts, fn ^env -> [h1] end)

        call = fn ->
          capture_io(:stderr, fn ->
            HostFilter.host(env, ["-h", filter])
          end)
        end

        assert catch_exit(call.()) == {:shutdown, 1}
      end
    end

    property "error when several configured and filter doesn't match any" do
      check all env <- env(),
                h1 <- ?a..?z |> nonempty_string(),
                h2 <- ?a..?z |> nonempty_string(),
                filter <- ?0..?9 |> nonempty_string() do
        HostProviderMock
        |> expect(:hosts, fn ^env -> [h1, h2] end)

        call = fn ->
          capture_io(:stderr, fn ->
            HostFilter.host(env, ["-h", filter])
          end)
        end

        assert catch_exit(call.()) == {:shutdown, 1}
      end
    end

    property "asks user when several configured and filter matches more than one" do
      check all env <- env(),
                filter <- nonempty_string(),
                h1_suffix <- nonempty_string(),
                h2_prefix <- nonempty_string() do
        [position] = 0..1 |> Enum.take_random(1)
        h1 = filter <> h1_suffix
        h2 = h2_prefix <> filter
        hosts = [h1, h2]

        HostProviderMock
        |> expect(:hosts, fn ^env -> hosts end)

        output =
          capture_io([input: "#{position}\n", capture_prompt: true], fn ->
            {:ok, host} = HostFilter.host(env, ["-h", filter])
            TestAgent.set(:host, host)
          end)

        assert output ==
                 "\e[1m[0] \e[0m\e[33m#{h1}\e[0m\n\e[1m[1] \e[0m\e[33m#{h2}\e[0m\nChoose a number: "

        assert TestAgent.get(:host) == Enum.at(hosts, position)
      end
    end

    property "asks user again when user provides bad position" do
      check all env <- env(),
                filter <- nonempty_string(),
                h1_suffix <- nonempty_string(),
                h2_prefix <- nonempty_string(),
                bad_tries <- 2..42 |> integer() |> list_of() |> nonempty() do
        [position] = 0..1 |> Enum.take_random(1)
        h1 = filter <> h1_suffix
        h2 = h2_prefix <> filter
        hosts = [h1, h2]
        bad_input = bad_tries |> Enum.map(&"#{&1}\n") |> Enum.join("")

        output =
          "\e[1m[0] \e[0m\e[33m#{h1}\e[0m\n\e[1m[1] \e[0m\e[33m#{h2}\e[0m\nChoose a number: "

        expected_output =
          0..Enum.count(bad_tries)
          |> Enum.map(fn _ -> output end)
          |> Enum.join("")

        HostProviderMock
        |> expect(:hosts, fn ^env -> hosts end)

        output =
          capture_io([input: "#{bad_input}#{position}\n", capture_prompt: true], fn ->
            {:ok, host} = HostFilter.host(env, ["-h", filter])
            TestAgent.set(:host, host)
          end)

        assert output == expected_output

        assert TestAgent.get(:host) == Enum.at(hosts, position)
      end
    end
  end
end
