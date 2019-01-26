defmodule Deli.MixProject do
  use Mix.Project

  def project do
    [
      app: :deli,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  def application do
    [
      mod: {Deli.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:edeliver, "~> 1.6.0"},
      {:distillery, "~> 2.0.10"},
      {:ex_doc, "~> 0.19.1", only: :docs},
      {:credo, "~> 1.0.0", only: :test},
      {:dialyxir, "~> 1.0.0-rc.4", only: :test}
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
end
