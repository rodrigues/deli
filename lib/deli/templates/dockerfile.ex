defmodule Deli.Templates.Dockerfile do
  require EEx

  EEx.function_from_file(
    :def,
    :build_centos,
    Path.expand("lib/templates/.deliver/Dockerfile/centos.eex"),
    [:app]
  )

  def build(:centos, args) when is_list(args), do: build_centos(args)
end
