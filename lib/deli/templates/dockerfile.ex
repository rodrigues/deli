defmodule Deli.Templates.Dockerfile do
  require EEx

  @moduledoc false

  EEx.function_from_file(
    :def,
    :build_centos,
    Path.expand("lib/templates/.deliver/Dockerfile/centos.eex"),
    ~w(app yarn?)a
  )

  def build(:centos, app, yarn?) do
    app |> build_centos(yarn?)
  end
end
