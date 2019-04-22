# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :phoenix, :json_library, Jason

# General application configuration
config :slax, ecto_repos: [Slax.Repo]

# Configures the endpoint
config :slax, SlaxWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "N4gXL4rdXzHD9kNbCBAaEKShN+mxlgX0biU+eMpc766DF1TYFf2o9kkDLvHNfv1Y",
  render_errors: [view: SlaxWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Slax.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :slax, http_adapter: HTTPoison

config :slax, :lintron,
  secret: System.get_env("LINTRON_SECRET"),
  url: System.get_env("LINTRON_URL")

config :slax, :board_checker,
  secret: System.get_env("BOARD_CHECKER_SECRET"),
  url: System.get_env("BOARD_CHECKER_URL")

config :slax, :reusable_stories,
  repo: System.get_env("REUSABLE_STORIES_REPO"),
  paths: [
    prework: "stories/pre-work",
    registration: "stories/registration",
    startproject: "stories/start-project"
  ]

config :slax, Slax.Github,
  api_url: "https://api.github.com",
  oauth_url: "https://github.com/login/oauth",
  client_id: System.get_env("GITHUB_CLIENT_ID"),
  client_secret: System.get_env("GITHUB_CLIENT_SECRET"),
  org_name: System.get_env("GITHUB_ORG_NAME"),
  org_teams: System.get_env("GITHUB_ORG_TEAMS"),
  api_token: System.get_env("GITHUB_API_TOKEN")

config :slax, Slax.Slack,
  api_url: "https://slack.com/api",
  api_token: System.get_env("SLACK_TOKEN"),
  tokens: [
    slax: System.get_env("SLAX_SLACK_TOKEN"),
    comment: System.get_env("COMMENT_SLACK_TOKEN"),
    issue: System.get_env("ISSUE_SLACK_TOKEN"),
    auth: System.get_env("AUTH_SLACK_TOKEN"),
    tarpon: System.get_env("TARPON_SLACK_TOKEN"),
    project: System.get_env("PROJECT_SLACK_TOKEN"),
    sprint: System.get_env("SPRINT_SLACK_TOKEN"),
    blocker: System.get_env("BLOCKER_SLACK_TOKEN")
  ]
config :slax, Slax.Scheduler,
  jobs: [
    # schedule for 9:25 monday thru friday (14:30 UTC)
    blockerbot: [
      schedule: "25 14 * * 1,2,3,4,5",
      task: {Slax.Scheduler, :start, []}
    ]
  ]


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
