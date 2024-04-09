import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :slax, SlaxWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :slax, http_adapter: Slax.HttpMock
config :slax, github_commands: Slax.Commands.GithubCommandsMock
config :slax, tentacat_issues: Slax.Tentacat.IssuesMock

# Configure your database
config :slax, Slax.Repo,
  database: "slax_test",
  hostname: "localhost",
  username: "postgres",
  password: "postgres",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox

config :slax, Slax.Slack,
  api_token: "token",
  tokens: [
    comment: "token",
    issue: "token",
    auth: "token",
    tarpon: "token",
    project: "token",
    sprint: "token",
    slax: "token",
    blocker: "token",
    inspire: "token"
  ]

config :slax, Slax.Github, org_name: "organization"

config :slax, SlaxWeb.WebsocketListener, enabled: false

config :slax, Oban, testing: :inline
