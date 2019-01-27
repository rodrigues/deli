# Deli

Provides a deploy task for Elixir applications, using a few [`edeliver`](https://github.com/edeliver/edeliver) [tasks](https://hexdocs.pm/edeliver/Mix.Tasks.Edeliver.html#content) under the hood.

Releases are built locally with docker containers, and systemd's systemctl is used by default for controlling the app (`systemctl (restart | status)`). You can configure another controller.


Git tags are enforced to keep versioning relevant, and matching with your `mix.exs`.

## Configuration

Add `deli` to your deps:

```elixir
def deps do
  [
    # ...
    {:deli, "~> 0.1.14", runtime: false}
  ]
end
```

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

```
$ mix deli
```

The command above does full cycle deploy:

- Creates a local build environment (docker)
- Builds release in this container (edeliver)
- Deploys release to target environment (edeliver)
- Restart target apps (systemctl)
- Checks status (systemctl)

It will assume `staging` environment by default.

To target `prod` environment, do:

```
$ mix deli -t prod
```

It will ask for confirmation after release is built, before deploy.
If you don't want that extra step, pass `-y` when calling this task.

For more deploy options, do:

```
$ mix help deli
```

Other convenience tasks provided by deli:

```
# Starts all hosts for target prod
$ mix deli.start -t prod

# Stops all hosts for target prod, without confirmation
$ mix deli.stop -t prod -y

# Restarts all hosts for target staging
$ mix deli.restart
```

Releases should be configured in your application with [`distillery`](https://hexdocs.pm/distillery).

You don't need to think about edeliver with deli (unless you want to).
Deli generates any config needed for edeliver, and adds them to your gitignore by default.
If you want to maintain a custom version, just remove from .gitignore.

At the moment, this package exists for reusing among similarly configured apps. It might not be flexible enough for your needs yet.

## Potential future work

- Remove edeliver dependency, replacing its steps by local code
- Accept regex pattern in the end of task(s) to filter hosts affected by command
- Add documentation, tests and typespecs
- Log in debug mode
- Allow configuration for other admin tools (systemctl / edeliver / ?)
- Allow configuring other docker build targets (currently only centos:7.6)
- Allow configuring docker build elixir / otp / rebar versions
- Provide default distillery config (distillery)
- Default release service assets (nginx, systemd, logrotate etc)
- Parallel restarts
- Retry / rollback strategy
- Upgrades
- Quiet mode
- PRs are welcome! The intent is to keep this task simple to use over time, and add flexibility through configuration rather than CLI args or ENV, providing good defaults.
