defmodule Mix.Tasks.Deli do
  use Mix.Task

  defdelegate run(args), to: Mix.Tasks.Deli.Deploy
end
