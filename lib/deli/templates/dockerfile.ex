defmodule Deli.Templates.Dockerfile do
  require EEx
  alias Deli.BeamVersions
  alias Deli.Release.Docker

  @moduledoc false

  @base_path "lib/templates/.deli/Dockerfile"

  @deli_images ~w(
    centos
    debian
  )a

  @deli_bindings ~w(
    tag
    versions
    app
    user
    yarn?
    node_version
  )a

  @custom_bindings ~w(
    docker_image
    app
    user
    _yarn?
    _node_version
  )a

  path = &Path.expand("#{@base_path}/#{&1}.eex")

  EEx.function_from_file(:def, :build_centos, path.(:centos), @deli_bindings)
  EEx.function_from_file(:def, :build_debian, path.(:debian), @deli_bindings)
  EEx.function_from_file(:def, :build_custom, path.(:custom), @custom_bindings)

  @spec build(Docker.build_target(), Deli.app(), atom, boolean, String.t()) :: String.t()
  def build({:deli, {deli_image, tag}, beam_versions_opts}, app, user, yarn?, node_version)
      when deli_image in @deli_images and (is_atom(tag) or is_binary(tag)) and
             is_atom(app) and is_atom(user) and is_boolean(yarn?) and
             is_binary(node_version) and is_list(beam_versions_opts) do
    beam_versions = beam_versions_opts |> BeamVersions.fetch()

    builder =
      case deli_image do
        :centos ->
          &build_centos/6

        :debian ->
          &build_debian/6
      end

    tag |> builder.(beam_versions, app, user, yarn?, node_version)
  end

  def build({:deli, {deli_image, tag}}, app, user, yarn?, node_version) do
    {:deli, {deli_image, tag}, []} |> build(app, user, yarn?, node_version)
  end

  def build({:deli, deli_image}, app, user, yarn?, node_version) do
    {:deli, {deli_image, :latest}} |> build(app, user, yarn?, node_version)
  end

  def build({:deli, deli_image, beam_versions}, app, user, yarn?, node_version) do
    {:deli, deli_image, beam_versions} |> build(app, user, yarn?, node_version)
  end

  def build(docker_image, app, user, yarn?, node_version)
      when (is_atom(docker_image) or is_binary(docker_image)) and
             is_atom(app) and is_atom(user) and is_boolean(yarn?) and is_binary(node_version) do
    docker_image |> build_custom(app, user, yarn?, node_version)
  end

  def build({docker_image, tag}, app, user, yarn?, node_version)
      when (is_atom(docker_image) or is_binary(docker_image)) and
             is_atom(app) and is_atom(user) and is_boolean(yarn?) and is_binary(node_version) do
    "#{docker_image}:#{tag}" |> build(app, user, yarn?, node_version)
  end
end
