import Config

if config_env() == :prod do
  config :slax, SlaxWeb.Endpoint,
    server: true,
    url: [host: "#{System.get_env("FLY_APP_NAME")}.fly.dev", port: 80],
    http: [
      port: String.to_integer(System.get_env("PORT") || "4000"),
      transport_options: [socket_opts: [:inet6]]
    ],
    secret_key_base: System.get_env("SECRET_KEY_BASE")

  config :slax, Slax.Repo,
    url: System.get_env("DATABASE_URL"),
    # IMPORTANT: Or it won't find the DB server
    socket_options: [:inet6],
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  config :slax, Slax.Slack,
    client_id: System.get_env("SLACK_CLIENT_ID"),
    client_secret: System.get_env("SLACK_CLIENT_SECRET")
end
