defmodule Deli.HostFilterTest do
  use DeliCase
  alias Deli.HostFilter

  describe "hosts/0" do
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
  end
end
