defmodule Slax.Mixfile do
  use Mix.Project

  def project do
    [
      app: :slax,
      version: "0.0.1",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Slax, []},
      extra_applications: [:logger, :ssl]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.0", override: true},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.10.2"},
      {:postgrex, ">= 0.0.0"},
      {:gettext, "~> 0.18"},
      {:plug_cowboy, "~> 2.5"},
      {:plug, "~> 1.12.1"},
      {:httpoison, "~> 1.5"},
      {:yaml_front_matter, "~> 1.0"},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      {:mox, "~> 0.3", only: :test},
      {:jason, "~> 1.1"},
      {:ex_machina, "~> 2.2", only: :test},
      {:stream_data, "~> 0.4.3", only: :test},
      {:quantum, "~> 3.0"},
      {:timex, "~> 3.7"},
      {:tentacat, "~> 1.6.0"},
      {:inflex, "~> 2.0.0"},
      {:credo, "~> 1.5.0", only: [:dev, :test], runtime: false},
      {:gun, "~> 2.0.1"},
      {:oban, "~> 2.13"},
      {:certifi, "~> 2.8.0"},
      {:castore, "~> 1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
