defmodule Deli.Templates.EdeliverConfig do
  require EEx

  @moduledoc false

  EEx.function_from_file(
    :def,
    :build,
    Path.expand("lib/templates/.deli/edeliver_config.eex"),
    ~w(
      app
      staging_hosts
      production_hosts
      staging_user
      production_user
      docker_build_user
      docker_build_port
      remote?
      remote_build_host
      remote_build_user
    )a
  )
end
