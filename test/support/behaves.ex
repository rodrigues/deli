defmodule Behaves do
  def behaves?(mod, behaviour) do
    mod.module_info()[:attributes][:behaviour]
    |> Enum.member?(behaviour)
  end
end
