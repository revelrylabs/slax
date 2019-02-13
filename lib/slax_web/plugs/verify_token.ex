defmodule Slax.Plugs.VerifySlackToken do
  import Phoenix.Controller, only: [text: 2]
  import Plug.Conn, only: [halt: 1]
  require Logger

  def init(app_var) do
    tokens = Application.get_env(:slax, Slax.Slack)[:tokens]
    Keyword.get(tokens, app_var)
  end

  def call(%Plug.Conn{params: %{"token" => token}} = conn, local_token) do
    Logger.info("token: #{inspect(token)}, local_token: #{inspect(local_token)}")

    case token == local_token do
      true ->
        conn

      false ->
        text(conn, "Invalid slack token.") |> halt
    end
  end

  def call(conn, _) do
    conn
  end
end
