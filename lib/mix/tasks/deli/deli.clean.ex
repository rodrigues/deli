defmodule Mix.Tasks.Deli.Clean do
  use Mix.Task
  import Deli.Shell

  @moduledoc """
  This task cleans autogenerated config files

      $ mix deli.clean
  """

  @shortdoc "Cleans autogenerated config files"

  @clean_paths ~w(
    .deliver/config
    .deliver/Dockerfile
    .deliver-docker-compose.yml
  )

  def run(_args) do
    _ = Application.ensure_all_started(:deli)
    releases_path = ".deliver/releases" |> expand_path
    cmd(:rm, ["-rf", releases_path], [0, 1])
    @clean_paths |> Enum.each(&remove_if_autogenerated/1)
  end

  defp remove_if_autogenerated(path) do
    path = path |> expand_path

    if path |> file_exists? do
      if File.read!(path) =~ ~r/autogenerated by deli/ do
        cmd(:rm, [path])
      end
    end
  end
end