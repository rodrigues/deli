defmodule Deli.HostFilterTest do
  use DeliCase
  alias Deli.HostFilter

  describe "hosts/0" do
    property "all hosts when not filtering" do
      check all e <- atom(),
                h1 <- non_empty_string(),
                h2 <- non_empty_string() do
        h3 = h1 <> h2

        HostProviderMock
        |> expect(:hosts, fn ^e -> [h1, h2, h3] end)

        output =
          capture_io(fn ->
            {:ok, [^h1, ^h2, ^h3]} = e |> HostFilter.hosts([])
          end)

        assert output == "# hosts\n## #{h1}\n## #{h2}\n## #{h3}\n"
      end
    end

    property "filters hosts" do
      check all e <- atom(),
                h1 <- ?a..?k |> non_empty_string(),
                h2 <- ?l..?z |> non_empty_string(),
                term_size <- 1..5 |> integer() do
        h3 = h1 <> h2

        HostProviderMock
        |> expect(:hosts, fn ^e -> [h1, h2, h3] end)

        {filter, _} = h1 |> String.split_at(term_size)

        output =
          capture_io(fn ->
            {:ok, [^h1, ^h3]} = e |> HostFilter.hosts(["-h", filter])
          end)

        assert output == "# hosts\n## #{h1}\n## #{h3}\n"
      end
    end

    property "fails if all hosts are excluded after filter" do
      check all e <- atom(),
                h1 <- ?a..?k |> non_empty_string(),
                h2 <- ?l..?z |> non_empty_string(),
                filter <- ?0..?9 |> non_empty_string() do
        h3 = h1 <> h2

        HostProviderMock
        |> expect(:hosts, fn ^e -> [h1, h2, h3] end)

        call = fn ->
          capture_io(:stderr, fn ->
            HostFilter.hosts(e, ["-h", filter])
          end)
        end

        assert catch_exit(call.()) == {:shutdown, 1}
      end
    end

    property "fails if no hosts are defined for env and filtering" do
      check all e <- atom(),
                filter <- ?a..?z |> non_empty_string() do
        HostProviderMock
        |> expect(:hosts, fn ^e -> [] end)

        call = fn ->
          capture_io(:stderr, fn ->
            HostFilter.hosts(e, ["-h", filter])
          end)
        end

        assert catch_exit(call.()) == {:shutdown, 1}
      end
    end

    property "fails if no hosts are defined for env and not filtering" do
      check all e <- atom() do
        HostProviderMock
        |> expect(:hosts, fn ^e -> [] end)

        call = fn ->
          capture_io(:stderr, fn ->
            HostFilter.hosts(e, [])
          end)
        end

        assert catch_exit(call.()) == {:shutdown, 1}
      end
    end
  end
end
