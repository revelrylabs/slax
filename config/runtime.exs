import Config

if config_env() == :prod do
  config :slax, Slax.Repo,
    url: System.get_env("DATABASE_URL"),
    ssl: true,
    ssl_opts: [verify: :verify_peer, cacertfile: CAStore.file_path()],
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    queue_target: String.to_integer(System.get_env("QUEUE_TARGET") || "5000")

  port = String.to_integer(System.get_env("PORT"))

  config :slax, SlaxWeb.Endpoint,
    http: [port: port, compress: true],
    url: [scheme: "https", host: System.get_env("APP_DOMAIN"), port: 443, compress: true],
    secret_key_base: System.get_env("SECRET_KEY_BASE")

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
    channel_name: System.get_env("SLACK_CHANNEL_NAME"),
    app_token: System.get_env("SLACK_APP_TOKEN"),
    tokens: [
      comment: System.get_env("COMMENT_SLACK_TOKEN"),
      issue: System.get_env("ISSUE_SLACK_TOKEN"),
      auth: System.get_env("AUTH_SLACK_TOKEN"),
      tarpon: System.get_env("TARPON_SLACK_TOKEN"),
      project: System.get_env("PROJECT_SLACK_TOKEN"),
      sprint: System.get_env("SPRINT_SLACK_TOKEN"),
      slax: System.get_env("SLAX_SLACK_TOKEN"),
      blocker: System.get_env("BLOCKER_SLACK_TOKEN")
    ]

  config :slax, Slax.EventSink, issue_events_secret: System.get_env("ISSUE_EVENTS_SECRET")
end
