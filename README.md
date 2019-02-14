# Deli

[![Build Status](https://travis-ci.org/rodrigues/deli.svg?branch=master)](https://travis-ci.org/rodrigues/deli)
[![Hex.pm](https://img.shields.io/hexpm/v/deli.svg)](https://hex.pm/packages/deli)
[![Hexdocs.pm](https://img.shields.io/badge/api-hexdocs-brightgreen.svg)](https://hexdocs.pm/deli)

Provides a simple deployment solution for Elixir applications, using a couple of [`edeliver`](https://github.com/edeliver/edeliver) [tasks](https://hexdocs.pm/edeliver/Mix.Tasks.Edeliver.html#content) under the hood.

Releases are built with [`distillery`](https://github.com/bitwalker/distillery), locally, through docker.

Git tags are autogenerated, and `deli` will ask you to bump app version, if there are new commits since last version bump.

You can configure a different release / versioning strategy if you want to.

## Getting Started

Minimal versions required: Elixir 1.8+, OTP 20+.

Add `deli` to your deps:

```elixir
def deps do
  [
    # ...
    {:deli, "~> 0.2.0-rc.1", runtime: false}
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

## Main task

```bash
$ mix deli
```

The task above does full cycle deploy:

- Creates a local docker build env
- Builds a new release in this env
- Deploys release to target env hosts
- Restarts each app in target hosts, and checks their status

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

# Checks status in all prod hosts
$ mix deli.status -t prod

# Pings all staging hosts (bin ping)
$ mix deli.ping

# Checks version in all staging hosts that match ~r/01/
$ mix deli.version -h 01

# Checks local version
$ mix deli.version -t dev

# Compares local version with all prod hosts
$ mix deli.version -c -t prod

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

#### Edeliver and Distillery

Releases should be configured in your application with [`distillery`](https://hexdocs.pm/distillery).

You don't need to think about edeliver with `deli` (unless you want to).
Deli generates any config needed for edeliver, and adds them to your gitignore by default.
If you want to maintain a custom version, just remove from .gitignore, and also remove the comment line saying `autogenerated by deli`.
Edeliver mix commands are available to you. But if you use the systemctl controller, avoid using edeliver admin commands (start / stop / ...)

At the moment, this package exists for reusing among similarly configured apps. It might not be flexible enough for your needs yet.

### Advanced configuration

Checkout [Release configuration](https://hexdocs.pm/deli/release.html) for more options.

## Potential future work

- Add more docs, tests, guards and typespecs
- Remove edeliver dependency, replacing its steps by local code
- Concurrent restarts / checks / ...
- Retry / rollback strategy
- Upgrades
- Accept host labels in config, and filter by it in commands
- Associate labels with different build targets (first label wins)
- Configure a custom deploy strategy
- Plugin behaviour to allow custom hooks and integrations (e.g. slack notification)
- Use github releases as release store
- Allow production to be default target if there's no staging
- mix deli.eval
- Allow developers to create custom docker build hooks, by checking paths: `.deli/docker_build_hooks/{(before_|after)(build|setup|setup_(otp|elixir|rebar3))}/script.(sh|exs)`
- Allow to change target path to something else than `/opt/APP`
- Autogenerated files with version and checksums for expiration
- Integrate with a terminal-based observer
- Do rebar3 checksum in docker build images
- Allow to specify hex version in docker build images
- Configure a remote docker host
- Provide common release service assets (nginx, systemd, logrotate etc)
- Provision/setup new target hosts (with hooks for custom setup)
- Use s3 as release store
- Use a scp release store (allows CI to build releases for all build targets upfront)
