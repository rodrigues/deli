defmodule Deli.MixProject do
  use Mix.Project

  def project do
    [
      app: :deli,
      version: "0.2.0-rc.1",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      application: application(),
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs(),
      package: package(),
      source_url: "https://github.com/rodrigues/deli",
      homepage_url: "https://hexdocs.pm/deli",
      description: "A deploy task for Elixir applications"
    ]
  end

  def application do
    [
      extra_applications: [:mix, :logger]
    ]
  end

  defp elixirc_paths(:test), do: ~w(lib test/support)
  defp elixirc_paths(_), do: ~w(lib)

  defp deps do
    [
      {:edeliver, "~> 1.6.0", runtime: false},
      {:distillery, "~> 2.0.10", runtime: false},
      {:ex_doc, "~> 0.19.1", only: :dev, runtime: false},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 0.4.2", only: :test},
      {:mox, "~> 0.5.0", only: :test}
    ]
  end

  defp dialyzer do
    [
      plt_add_deps: :apps_direct,
      plt_add_apps: ~w(
        ex_unit
        inets
        jason
        mix
      )a,
      flags: ~w(
        error_handling
        race_conditions
        unmatched_returns
        underspecs
      )a,
      ignore_warnings: ".dialyzer_ignore.exs"
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ~w(
        README.md
        guides/Release.md
      ),
      groups_for_modules: [
        Controller: [
          Deli.Controller,
          Deli.Controller.Bin,
          Deli.Controller.Systemctl
        ],
        Release: [
          Deli.Release,
          Deli.Release.Remote,
          Deli.Release.Docker
        ],
        "Host provider": [
          Deli.HostProvider,
          Deli.HostProvider.Config
        ],
        Versioning: [
          Deli.Versioning,
          Deli.Versioning.Default
        ]
      ]
    ]
  end

  defp package do
    [
      maintainers: ["Victor Rodrigues"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/rodrigues/deli"}
    ]
  end
end
