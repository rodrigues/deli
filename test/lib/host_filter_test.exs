defmodule Deli.HostFilterTest do
  use DeliCase
  alias Deli.HostFilter

  describe "hosts/0" do
    property "filters hosts" do
      empty? = &(&1 == "")

      check all e <- atom(),
                h1 <- ?a..?k |> string() |> except(empty?),
                h2 <- ?l..?z |> string() |> except(empty?),
                term_size <- integer(1..5) do
        h3 = h1 <> h2
        put_config(:hosts, [{e, [h1, h2, h3]}])

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
