defmodule Slax.Mixfile do
  use Mix.Project

  def project do
    [
      app: :slax,
      version: "0.0.1",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
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
      {:phoenix, "~> 1.8.3", override: true},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.7"},
      {:ecto_sql, "~> 3.13.4"},
      {:postgrex, "~> 0.21.1"},
      {:plug_cowboy, "~> 2.7.5"},
      {:plug, "~> 1.19.1"},
      {:httpoison, "~> 1.5"},
      {:yaml_front_matter, "~> 1.0"},
      {:ex_doc, "~> 0.39.3", only: :dev, runtime: false},
      {:mox, "~> 1.1", only: :test},
      {:jason, "~> 1.1"},
      {:ex_machina, "~> 2.2", only: :test},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 1.2.0", only: :test},
      {:quantum, "~> 3.0"},
      {:timex, "~> 3.7"},
      {:tentacat, "~> 2.2.0"},
      {:credo, "~> 1.7.15", only: [:dev, :test], runtime: false},
      {:inflex, "~> 2.1.0"},
      {:gun, "~> 2.0.1"},
      {:oban, "~> 2.20.2"},
      {:certifi, "~> 2.8.0"},
      {:castore, "~> 1.0.17"},
      {:phoenix_view, "~> 2.0"}
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
