defmodule StreamDataExclude do
  def term_except(predicate) do
    StreamData.term()
    |> StreamData.filter(fn a -> not predicate.(a) end, 1_000)
  end
end
