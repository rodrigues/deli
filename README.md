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
    {:deli, "~> 0.1.16", runtime: false}
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

# Restarts all hosts for target staging, without confirmation
$ mix deli.restart -y

# Cleans autogenerated config files
$ mix deli.clean

# Does only docker release phase
$ mix deli.release

# Does only deploy/restart/check (release should be available)
$ mix deli.deploy
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
- Provide default distillery config
- Parallel restarts / checks / ...
- Retry / rollback strategy
- Upgrades
- Accept regex pattern in the end of task(s) to filter hosts affected by command
- Before confirmation, list all affected hosts
- Add docker build target to latest debian and ubuntu
- Allow configuring a docker image identifier as docker build target
- Allow configuring docker build elixir / otp / rebar versions (mind the checksums)
- Accept host tags in config, and filter by it in commands
- Associate tags with different build targets (first tag wins)
- Allow configuration of a custom host provider (default: config hosts)
- Add more docs, tests and typespecs
- Default release service assets (nginx, systemd, logrotate etc)
- Autogenerated files with version and checksums for expiration
- PRs are welcome! The intent is to keep this task simple to use over time, and add flexibility through configuration rather than CLI args or ENV, providing good defaults.
