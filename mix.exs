defmodule Slax.MixProject do
  use Mix.Project

  def project do
    [
      app: :slax,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_paths: ["lib"],
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Slax.Application, []},
      extra_applications: extra_applications(Mix.env())
    ]
  end

  defp extra_applications(:dev) do
    [:logger, :runtime_tools]
  end

  defp extra_applications(_), do: []

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test_support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, github: "phoenixframework/phoenix", branch: "v1.5", override: true},
      {:esbuild, "~> 0.1", runtime: Mix.env() == :dev},
      {:phoenix_ecto, "~> 4.2"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, "~> 0.15.9"},
      {:phoenix_live_view, "~> 0.15.7"},
      {:phoenix_html, "~> 2.14"},
      {:phoenix_live_reload, "~> 1.3"},
      {:telemetry_metrics, "~> 0.6.0"},
      {:telemetry_poller, "~> 0.5.1"},
      {:gettext, "~> 0.18.2"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:surface, "~> 0.5.0"},
      {:surface_formatter, "~> 0.5.0"},
      {:faker, "~> 0.16"},
      {:websockex, "~> 0.4.3"},
      {:httpoison, "~> 1.8"},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_machina, "~> 2.7"},
      {:oban, "~> 2.7"},
      {:cloak_ecto, "~> 1.2"},
      {:timex, "~> 3.7"},
      {:scrivener_ecto, "~> 2.7"},
      {:nimble_csv, "~> 1.1"},
      {:floki, ">= 0.30.0", only: :test},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      compile: compile(Mix.env()),
      setup: ["deps.get", "ecto.setup", "cmd --cd assets npm install"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "test.watch": ["ecto.create --quiet", "ecto.migrate --quiet", "test.watch"],
      "assets.deploy": [
        "cmd --cd assets npm run deploy",
        "esbuild default --minify",
        "phx.digest"
      ],
      format_all: ["format", "surface.format"],
      checks: ["credo --strict", "format --check-formatted", "surface.format --check-formatted"]
    ]
  end

  defp compile(:dev), do: ["compile"]
  defp compile(_), do: ["compile --warnings-as-errors"]
end
