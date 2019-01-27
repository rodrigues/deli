defmodule Deli.Templates.EdeliverConfig do
  require EEx

  @moduledoc false

  EEx.function_from_file(
    :def,
    :build,
    Path.expand("lib/templates/.deliver/config.eex"),
    [:app, :staging_hosts, :production_hosts, :docker_port]
  )
end
