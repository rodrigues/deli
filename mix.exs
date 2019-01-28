defmodule Deli.MixProject do
  use Mix.Project

  def project do
    [
      app: :deli,
      version: "0.1.22",
      elixir: "~> 1.8",
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

  defp deps do
    [
      {:edeliver, "~> 1.6.0", runtime: false},
      {:distillery, "~> 2.0.10", runtime: false},
      {:ex_doc, "~> 0.19.1", only: :dev, runtime: false},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp dialyzer do
    [
      plt_add_deps: :apps_direct,
      plt_add_apps: ~w(
        ex_unit
        mix
      )a,
      flags: ~w(
        error_handling
        race_conditions
        unmatched_returns
      )a,
      ignore_warnings: ".dialyzer_ignore.exs"
    ]
  end

  defp docs do
    [main: "readme", extras: ["README.md"]]
  end

  defp package do
    [
      maintainers: ["Victor Rodrigues"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/rodrigues/deli"}
    ]
  end
end
