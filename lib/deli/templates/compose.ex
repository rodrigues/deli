defmodule Deli.Templates.Compose do
  require EEx

  @moduledoc false

  EEx.function_from_file(
    :def,
    :build,
    Path.expand("lib/templates/.deli/docker-compose.yml.eex"),
    [:app, :docker_port]
  )
end
