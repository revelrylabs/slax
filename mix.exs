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
      deps: deps(),
      listeners: [Phoenix.CodeReloader],
      # NOTE: CVE-2026-43966 is in cowlib's cow_http_struct_hd:escape_string/2, which has
      # no fixed cowlib release. cowboy 2.16+ and gun 2.4+ reject CR and LF in headers
      # before they reach cowlib, both are above that here, and slax does not call
      # cowlib directly. GitHub's gun entry names a patched version that does not
      # exist; github/advisory-database#9445 corrects it. Remove when cowlib ships a fix.
      hex: [ignore_advisories: ["CVE-2026-43966"]]
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
      {:phoenix, "~> 1.8.5", override: true},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.7"},
      {:ecto_sql, "~> 3.14.0"},
      {:postgrex, "~> 0.22.0"},
      {:plug_cowboy, "~> 2.9.0"},
      {:plug, "~> 1.20.3"},
      # NOTE: tentacat 2.2.0 declares httpoison ~> 1.0. httpoison 3 brings hackney 4,
      # which carries the 2026 hackney CVE fixes. Drop the override when tentacat
      # allows httpoison 3.
      {:httpoison, "~> 3.0.0", override: true},
      {:yaml_front_matter, "~> 1.0"},
      {:ex_doc, "~> 0.40.1", only: :dev, runtime: false},
      {:mox, "~> 1.1", only: :test},
      {:jason, "~> 1.1"},
      {:ex_machina, "~> 2.2", only: :test},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 1.4.0", only: :test},
      {:quantum, "~> 3.0"},
      {:timex, "~> 3.7"},
      {:tentacat, "~> 2.2.0"},
      {:credo, "~> 1.7.18", only: [:dev, :test], runtime: false},
      {:inflex, "~> 2.1.0"},
      {:gun, "~> 2.6.0"},
      {:oban, "~> 2.24.1"},
      {:certifi, "~> 2.17.0"},
      {:castore, "~> 1.0.18"},
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
