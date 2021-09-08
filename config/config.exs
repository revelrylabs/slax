# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :slax,
  ecto_repos: [Slax.Repo]

# Configures the endpoint
config :slax, SlaxWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "zb2SzXmkfufNbj2oDTKOjpbxAd679GG4JGbTWVY1NaRNKLLarfR5KeF+bYpzzEba",
  render_errors: [view: SlaxWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Slax.PubSub,
  live_view: [signing_salt: "4Adt0nNh"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :slax, Oban,
  repo: Slax.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [fetch_data: 10, announce: 10]

config :slax, Slax.Vault,
  ciphers: [
    default:
      {Cloak.Ciphers.AES.GCM,
       tag: "AES.GCM.V1", key: Base.decode64!("ZQxNUCbSglo/blJVtll/SdH/dXDGDadVjvuChK9fLeg=")}
  ]

config :esbuild,
  version: "0.12.15",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
