# Deli

A simple deploy task for Elixir applications, using a few [`edeliver`](https://github.com/edeliver/edeliver) [tasks](https://hexdocs.pm/edeliver/Mix.Tasks.Edeliver.html#content) under the hood.

Releases are built locally with docker containers, and systemd is used for controlling the app (`systemctl (restart | status)`).


Git tags are enforced to keep versioning relevant, and matching with your `mix.exs`.

## Configuration

You don't need to think about edeliver with deli.
Deli generates any config needed for edeliver, and adds them to your gitignore by default.

Add `deli` to your deps:

```elixir
def deps do
  [
    # ...
    {:deli, "~> 0.1.3", only: :dev}
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
    production: [
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
- Pings application (edeliver)

It will assume `staging` environment by default.

To target `prod` environment, do:

```
$ mix deli -t prod
```

Using `production` is equivalent to `prod`.

For more deploy options, do:

```
$ mix help deli
```

Releases should be configured in your application with [`distillery`](https://hexdocs.pm/distillery).

At this point, this package exists to reuse a very simple flow for similarly configured apps. It might not be flexible enough for your needs yet.

## Potential future work

- Remove edeliver dependency, replacing its steps by local code
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
- PRs are welcome! The intent is to keep this task simple to use over time, and add flexibility through configuration rather than CLI args or ENV, providing good defaults.
