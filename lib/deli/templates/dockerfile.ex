defmodule Deli.Templates.Dockerfile do
  require EEx

  @moduledoc false

  @deli_images ~w(
    centos
    debian
  )a

  EEx.function_from_file(
    :def,
    :build_centos,
    Path.expand("lib/templates/.deliver/Dockerfile/centos.eex"),
    ~w(
      tag,
      app
      yarn?
    )a
  )

  EEx.function_from_file(
    :def,
    :build_debian,
    Path.expand("lib/templates/.deliver/Dockerfile/debian.eex"),
    ~w(
      tag,
      app
      yarn?
    )a
  )

  EEx.function_from_file(
    :def,
    :build_custom,
    Path.expand("lib/templates/.deliver/Dockerfile/custom.eex"),
    ~w(
      docker_image,
      app
      yarn?
    )a
  )

  @spec build(Docker.build_target(), Deli.app(), boolean) :: String.t()
  def build({:deli, deli_image}, app, yarn?)
      when deli_image in @deli_images and
             is_atom(app) and is_boolean(yarn?) do
    {:deli, {deli_image, :latest}} |> build(app, yarn?)
  end

  def build({:deli, {deli_image, tag}, app, yarn?})
      when deli_image in @deli_images and is_tag(tag) and
             is_atom(app) and is_boolean(yarn?) do
    builder =
      case deli_image do
        :centos ->
          &build_centos/3

        :debian ->
          &build_debian/3
      end

    tag |> builder.(app, yarn?)
  end

  def build(docker_image, app, yarn?)
      when (is_atom(docker_image) or is_binary(docker_image)) and
             is_atom(app) and is_boolean(yarn?) do
    docker_image |> build_custom(app, yarn?)
  end

  def build({docker_image, tag}, app, yarn?)
      when (is_atom(docker_image) or is_binary(docker_image)) and
             is_atom(app) and is_boolean(yarn?) do
    "#{docker_image}:#{tag}" |> build_custom(app, yarn?)
  end

  defguardp is_tag(tag)
            when is_atom(tag) or is_binary(tag) or
                   (is_integer(tag) and tag > 0)
end
