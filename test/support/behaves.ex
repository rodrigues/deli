defmodule Behaves do
  @moduledoc false

  def behaves?(mod, behaviour) do
    behaviours = mod.module_info()[:attributes][:behaviour]
    Enum.member?(behaviours, behaviour)
  end
end
