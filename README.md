# Deli

Provides a deploy task for Elixir applications, using a couple of [`edeliver`](https://github.com/edeliver/edeliver) [tasks](https://hexdocs.pm/edeliver/Mix.Tasks.Edeliver.html#content) under the hood.

Releases are built using [distillery](https://github.com/bitwalker/distillery), locally, through docker.

Git tags are autogenerated, and `deli` will ask to bump app version, if there are new commits since last version bump. You can switch to a custom versioning strategy if that's not good.

## Basic configuration

Add `deli` to your deps:

```elixir
def deps do
  [
    # ...
    {:deli, "~> 0.1.28", runtime: false}
  ]
end
```

You don't need to add `edeliver` or `distillery`, as they're already included.

No need for edeliver config (for basic scenario). You will need to [setup distillery](https://hexdocs.pm/distillery).

Then add some configuration in your `config/config.exs`:

```elixir
config :deli,
  hosts: [
    staging: [
      "staging-01.your_app.com",
      "staging-02.your_app.com"
    ],
    prod: [
      "prod-01.your_app.com",
      "prod-02.your_app.com",
      "prod-03.your_app.com",
      "prod-04.your_app.com",
      "prod-05.your_app.com",
      "prod-06.your_app.com"
    ]
  ]
```

See [`lib/deli/config.ex`](https://github.com/rodrigues/deli/blob/master/lib/deli/config.ex) for all configuration options (and their defaults).

## Deploy

```bash
$ mix deli
```

The task above does full cycle deploy:

- Create a local build env
- Build release in this env
- Deploys release to target env hosts
- Restart each app in target hosts, and check their status

It will assume `staging` environment by default.

To target `prod` environment, do:

```bash
$ mix deli -t prod
```

It will ask for confirmation after release is built, before deploy.
If you don't want that extra step, pass `-y` when calling this task.

### Other tasks provided by deli

```bash
# Starts all hosts for target prod
$ mix deli.start -t prod

# Stops all hosts for target prod, without confirmation
$ mix deli.stop -t prod -y

# Restarts all hosts for target staging that match ~r/02/
$ mix deli.restart -h 02

# Cleans autogenerated config files
$ mix deli.clean

# Does only docker release phase
$ mix deli.release

# Does only deploy/restart/check (release should be available)
$ mix deli.deploy

# Checks status
$ mix deli.status -t prod

# Checks version
$ mix deli.version

# Opens a IEx remote console from local machine
$ eval $(mix deli.shell)

# Opens a local observer connected to remote node
$ eval $(mix deli.shell -o)

# When there are more than one host for target,
# eval will just work if you filter it to just return one host
$ eval $(mix deli.shell -h 01)

# If you don't know yet how to filter, use it without eval,
# and it will do the port forwarding and print out the command to connect,
# but before, it lets you choose the host:
$ mix deli.shell
[0] staging-01.myapp.com
[1] staging-02.myapp.com
Choose a number: 0
iex --name local@127.0.0.1 --cookie awesome_cookie --remsh myapp@127.0.0.1
```

### Run mix tasks (locally) in remote nodes

By using [`Deli.Command`](https://hexdocs.pm/deli/Deli.Command.html), you can have this:

```shell
# runs locally
$ mix my_app.xyz --arg_example=1

# runs in all prod hosts
$ mix my_app.xyz --arg_example=1 -t prod

# runs in prod hosts matching ~r/03/
$ mix my_app.xyz --arg_example=1 -t prod -h 03
```

## Advanced Configuration

### Edeliver and Distillery

Releases should be configured in your application with [`distillery`](https://hexdocs.pm/distillery).

You don't need to think about edeliver with `deli` (unless you want to).
Deli generates any config needed for edeliver, and adds them to your gitignore by default.
If you want to maintain a custom version, just remove from .gitignore, and also remove the comment line saying `autogenerated by deli`.
Edeliver mix commands are available to you. But if you use the systemctl controller, avoid using edeliver admin commands (start / stop / ...)

At the moment, this package exists for reusing among similarly configured apps. It might not be flexible enough for your needs yet.

### Configuring docker image

By default, if you don't configure an image, a `deli` [centos image](https://github.com/rodrigues/deli/blob/master/lib/templates/.deli/Dockerfile/centos.eex) version is chosen.

You can also configure an image:

```elixir
# use deli's debian image, latest
config :deli, :docker_build_target, {:deli, :debian}

# use deli's centos image, based on this tag
config :deli, :docker_build_target, {:deli, {:centos, "7.6.1810"}}

# deli generates an image based on elixir official docker image
config :deli, :docker_build_target, :elixir

# deli generates an image based on elixir official docker image with this tag
config :deli, :docker_build_target, {:elixir, "1.8.0-alpine"}

# deli images can also have beam dependencies configured
#
# if you don't set it, latest version available
# when the package was generated will be used
#
beam_versions = [
  otp: "21.2.4",
  elixir: "1.8.0",
  rebar3: "3.6.1"
]

config :deli, :docker_build_target, {:deli, {:centos, "7.6.1810"}, beam_versions}
```

### Configuring controller

By default, the release binary (`/opt/APP/bin/APP`) is used to control the app (start, stop, restart, status, ping), but systemd's `systemctl` can be configured as the app controller:

```elixir
config :deli, :controller, Deli.Controller.Systemctl
```

You can configure any module that implements the [`Deli.Controller` behaviour](https://hexdocs.pm/deli/Deli.Controller.html). Beware during `v0.x.x` this contract is not stable.


## Potential future work

- Remove edeliver dependency, replacing its steps by local code
- Concurrent restarts / checks / ...
- Retry / rollback strategy
- Upgrades
- Accept host labels in config, and filter by it in commands
- Associate labels with different build targets (first label wins)
- Configure of a remote build host (docker as default behaviour)
- Configure a custom deploy strategy
- Plugin behaviour to allow custom hooks and integrations (e.g. slack notification)
- Autogenerated files with version and checksums for expiration
- Provide common release service assets (nginx, systemd, logrotate etc)
- Use a remote release store (allows CI to build releases for all build targets upfront)
- Provision/setup new target hosts (with hooks for custom setup)
- Integrate with a terminal-based observer
- In docker build, allow skipping user creation step, by configuring `docker_build_user :: atom` (default: `:deli`)
- Allow developers to create custom docker build hooks (`.deli/docker_hooks/{(before_|after)(build|setup|setup_(otp|elixir|rebar3))}/script.(sh|exs)`)
- Do rebar3 checksum in docker images
- Allow to pick one specific hex version
- Allow to change target path to something else than `/opt/APP`
- mix deli.version handle dev target
- mix deli.version have compare option
- mix deli.ping to run specifically bin ping command
- mix deli.eval
- Add more docs, tests, guards and typespecs
