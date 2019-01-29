# Deli

Provides a deploy task for Elixir applications, using a few [`edeliver`](https://github.com/edeliver/edeliver) [tasks](https://hexdocs.pm/edeliver/Mix.Tasks.Edeliver.html#content) under the hood.

Releases are built locally with docker containers.


Git tags are autogenerated, and `deli` will ask to bump app version, if there are new commits since last version bump.

## Configuration

Add `deli` to your deps:

```elixir
def deps do
  [
    # ...
    {:deli, "~> 0.1.26", runtime: false}
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

```bash
$ mix deli
```

The command above does full cycle deploy:

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

Other convenience tasks provided by deli:

```bash
# Starts all hosts for target prod
$ mix deli.start -t prod

# Stops all hosts for target prod, without confirmation
$ mix deli.stop -t prod -y

# Restarts all hosts for target staging that match the host filter
$ mix deli.restart 02

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
$ eval $(mix deli.shell 01)

# If you don't know yet how to filter, use it without eval,
# and it will do the port forwarding and print out the command to connect,
# but before, it lets you choose the host:
$ mix deli.shell
[0] staging-01.myapp.com
[1] staging-02.myapp.com
Choose a number: 0
iex --name local@127.0.0.1 --cookie awesome_cookie --remsh myapp@127.0.0.1
```

### Configuring controller

By default, the release binary (`/opt/APP/bin/APP`) is used to control the app (start, stop, restart, status, ping), but systemd's `systemctl` can be configured as the app controller:

```elixir
config :deli, controller: Deli.Controller.Systemctl
```

You can configure any module that implements the [`Deli.Controller` behaviour](https://hexdocs.pm/deli/Deli.Controller.html). Beware during `v0.x.x` this contract is not stable.

### Edeliver and Distillery

Releases should be configured in your application with [`distillery`](https://hexdocs.pm/distillery).

You don't need to think about edeliver with deli (unless you want to).
Deli generates any config needed for edeliver, and adds them to your gitignore by default.
If you want to maintain a custom version, just remove from .gitignore, and also remove the comment line saying `autogenerated by deli`.

At the moment, this package exists for reusing among similarly configured apps. It might not be flexible enough for your needs yet.

## Potential future work

- Remove edeliver dependency, replacing its steps by local code
- Concurrent restarts / checks / ...
- Retry / rollback strategy
- Upgrades
- Add docker build target to latest debian and ubuntu
- Allow configuring a docker image identifier as docker build target
- Allow configuring docker build elixir / otp / rebar versions (mind the checksums)
- Accept host labels in config, and filter by it in commands
- Associate labels with different build targets (first label wins)
- Configure a custom target host provider (default: config hosts behaviour)
- Configure of a remote build host (docker as default behaviour)
- Configure of a custom versioning behaviour
- Configure a custom deploy strategy
- Autogenerated files with version and checksums for expiration
- Provide common release service assets (nginx, systemd, logrotate etc)
- Use a remote release store (allows CI to build releases for all build targets upfront)
- Provision/setup new target hosts (with hooks for custom setup)
- mix deli.version handle dev target
- mix deli.version have compare option
- mix deli.status output whole status answer also when active, when verbose
- mix deli.ping to run specifically bin ping command
- mix deli.eval
- Add more docs, tests and typespecs
