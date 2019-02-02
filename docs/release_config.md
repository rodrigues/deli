## Release configuration

By default, the release will happen creating a docker machine to build the release with distillery.

You can change it by a custom one:

```elixir
# runs the release at a remote host
config :deli, :release, Deli.Release.Remote

# does something completely custom instead
config :deli, :release, Custom.Module
```

You can configure any module that implements `c:Deli.Release.build/2` callback.


#### Configuring docker build

By default, if you don't configure release, `Deli.Release.Docker` is the chosen behaviour.

You can configure details of this behaviour.

By default, the `deli` [centos image](https://github.com/rodrigues/deli/blob/master/lib/templates/.deli/Dockerfile/centos.eex) version is chosen.

You can configure a different image:

```elixir
# use deli's debian image, latest
config :deli, :docker_build, image: {:deli, :debian}

# use deli's centos image, based on this tag
config :deli, :docker_build, image: {:deli, {:centos, "7.6.1810"}}

# deli generates an image based on elixir official docker image
config :deli, :docker_build, image: :elixir

# deli generates an image based on elixir official docker image with this tag
config :deli, :docker_build, image: {:elixir, "1.8.0-alpine"}

# deli images can also have beam dependencies configured
#
# if you don't set it, latest stable version available
# when the package was generated will be used
#
beam_versions = [
  otp: "21.2.4",
  elixir: "1.8.0",
  rebar3: "3.6.1"
]

config :deli, :docker_build, image: {:deli, {:centos, "7.6.1810"}, beam_versions}
```

### Configuring controller

By default, the release binary (`/opt/APP/bin/APP`) is used to control the app (start, stop, restart, status, ping), but systemd's `systemctl` can be configured as the app controller:

```elixir
config :deli, :controller, Deli.Controller.Systemctl
```

You can configure any module that implements the [`Deli.Controller` behaviour](https://hexdocs.pm/deli/Deli.Controller.html).
