# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :slax,
  ecto_repos: [Slax.Repo]

# Configures the endpoint
config :slax, Slax.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "N4gXL4rdXzHD9kNbCBAaEKShN+mxlgX0biU+eMpc766DF1TYFf2o9kkDLvHNfv1Y",
  render_errors: [view: Slax.ErrorView, accepts: ~w(json)],
  pubsub: [name: Slax.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure your database
config :slax, Slax.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: {:system, "DATABASE_URL"}

config :slax, :github,
  client_id: System.get_env("GITHUB_CLIENT_ID"),
  client_secret: System.get_env("GITHUB_CLIENT_SECRET")

config :slax, :slack_tokens,
  issue: System.get_env("ISSUE_SLACK_TOKEN"),
  auth: System.get_env("AUTH_SLACK_TOKEN"),
  tarpon: System.get_env("TARPON_SLACK_TOKEN")

config :slax, :lintron,
  secret: System.get_env("LINTRON_SECRET"),
  url: System.get_env("LINTRON_URL")

config :slax, :board_checker,
  secret: System.get_env("BOARD_CHECKER_SECRET"),
  url: System.get_env("BOARD_CHECKER_URL")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
