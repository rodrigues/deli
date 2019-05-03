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

  defguardp is_normal(app, user, yarn?, node_version)
            when is_atom(app) and is_atom(user) and
                   is_boolean(yarn?) and is_binary(node_version)

  defguardp is_tag(tag) when is_atom(tag) or is_binary(tag)

  defguardp is_docker_image(image) when is_atom(image) or is_binary(image)

  @spec build(Docker.build_target(), Deli.app(), atom, boolean, String.t()) :: String.t()
  def build({:deli, {deli_image, tag}, beam_versions_opts}, app, user, yarn?, node_version)
      when deli_image in @deli_images and is_list(beam_versions_opts) and
             is_tag(tag) and is_normal(app, user, yarn?, node_version) do
    beam_versions = BeamVersions.fetch(beam_versions_opts)
    builder = builder(deli_image)
    builder.(tag, beam_versions, app, user, yarn?, node_version)
  end

  def build({:deli, {deli_image, tag}}, app, user, yarn?, node_version) do
    image = {:deli, {deli_image, tag}, []}
    build(image, app, user, yarn?, node_version)
  end

  def build({:deli, deli_image}, app, user, yarn?, node_version) do
    image = {:deli, {deli_image, :latest}}
    build(image, app, user, yarn?, node_version)
  end

  def build({:deli, deli_image, beam_versions}, app, user, yarn?, node_version) do
    image = {:deli, deli_image, beam_versions}
    build(image, app, user, yarn?, node_version)
  end

  def build(docker_image, app, user, yarn?, node_version)
      when is_docker_image(docker_image) and
             is_normal(app, user, yarn?, node_version) do
    build_custom(docker_image, app, user, yarn?, node_version)
  end

  def build({docker_image, tag}, app, user, yarn?, node_version)
      when is_docker_image(docker_image) and is_tag(tag) and
             is_normal(app, user, yarn?, node_version) do
    image = "#{docker_image}:#{tag}"
    build(image, app, user, yarn?, node_version)
  end

  defp builder(:centos), do: &build_centos/6
  defp builder(:debian), do: &build_debian/6
end
