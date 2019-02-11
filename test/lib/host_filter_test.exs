defmodule Deli.HostFilterTest do
  use DeliCase
  alias Deli.HostFilter

  describe "hosts/0" do
    property "filters hosts" do
      empty? = &(&1 == "")

      check all e <- atom(),
                h1 <- string(?a..?k) |> except(empty?),
                h2 <- string(?l..?z) |> except(empty?),
                term_size <- integer(1..5) do
        put_config(:hosts, [{e, [h1, h2]}])

        {filter, _} = h1 |> String.split_at(term_size)

        output =
          capture_io(fn ->
            {:ok, [^h1]} = e |> HostFilter.hosts(["-h", filter])
          end)

        assert output == "# hosts\n## #{h1}\n"
      end
    end
  end
end
