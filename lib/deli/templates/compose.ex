defmodule Deli.Templates.Compose do
  require EEx

  EEx.function_from_file(
    :def,
    :build,
    Path.expand("lib/templates/.deliver/docker-compose.yml.eex"),
    [:app, :docker_port]
  )
end
