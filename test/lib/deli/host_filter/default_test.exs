defmodule Deli.HostFilter.DefaultTest do
  use DeliCase, async: true
  alias Deli.HostFilter.Default, as: HostFilter

  test "behaviour" do
    assert behaves?(HostFilter, Deli.HostFilter)
  end

  def a_z, do: nonempty_string(?a..?z)
  def a_k, do: nonempty_string(?a..?k)
  def l_z, do: nonempty_string(?l..?z)
  def digit, do: nonempty_string(?0..?9)
  def position, do: 0..1 |> Enum.take_random(1) |> Enum.at(0)

  describe "hosts/2" do
    property "all hosts when not filtering" do
      check all env <- env(),
                h1 <- host(),
                h2 <- host() do
        h3 = h1 <> h2

        expect(HostProviderMock, :hosts, fn ^env -> [h1, h2, h3] end)

        output =
          capture_io(fn ->
            {:ok, [^h1, ^h2, ^h3]} = HostFilter.hosts(env, [])
          end)

        assert output == "# hosts\n## #{h1}\n## #{h2}\n## #{h3}\n"
      end
    end

    property "filters hosts" do
      check all env <- env(),
                h1 <- a_k(),
                h2 <- l_z(),
                term_size <- integer(1..5) do
        h3 = h1 <> h2

        expect(HostProviderMock, :hosts, fn ^env -> [h1, h2, h3] end)

        {filter, _} = String.split_at(h1, term_size)

        output =
          capture_io(fn ->
            {:ok, [^h1, ^h3]} = HostFilter.hosts(env, ["-h", filter])
          end)

        assert output == "# hosts\n## #{h1}\n## #{h3}\n"
      end
    end

    property "fails if all hosts are excluded after filter" do
      check all env <- env(),
                h1 <- a_k(),
                h2 <- l_z(),
                filter <- digit() do
        h3 = h1 <> h2

        expect(HostProviderMock, :hosts, fn ^env -> [h1, h2, h3] end)

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
                filter <- digit() do
        expect(HostProviderMock, :hosts, fn ^env -> [] end)

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
        expect(HostProviderMock, :hosts, fn ^env -> [] end)

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
        expect(HostProviderMock, :hosts, fn ^env -> [h1] end)
        assert {:ok, h1} == HostFilter.host(env, [])
      end
    end

    property "host when only one configured and filter matches" do
      check all env <- env(),
                h1 <- nonempty_string(),
                term_size <- integer(1..5) do
        expect(HostProviderMock, :hosts, fn ^env -> [h1] end)

        {filter, _} = String.split_at(h1, term_size)

        assert {:ok, h1} == HostFilter.host(env, ["-h", filter])
      end
    end

    property "error when only one configured and filter doesn't match" do
      check all env <- env(),
                h1 <- a_z(),
                filter <- digit() do
        expect(HostProviderMock, :hosts, fn ^env -> [h1] end)

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
                h1 <- a_z(),
                h2 <- a_z(),
                filter <- digit() do
        expect(HostProviderMock, :hosts, fn ^env -> [h1, h2] end)

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
        position = position()
        h1 = filter <> h1_suffix
        h2 = h2_prefix <> filter
        hosts = [h1, h2]

        expect(HostProviderMock, :hosts, fn ^env -> hosts end)

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
        position = position()
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

        expect(HostProviderMock, :hosts, fn ^env -> hosts end)

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
