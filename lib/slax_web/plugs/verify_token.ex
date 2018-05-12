defmodule Slax.Plugs.VerifySlackToken do
  import Phoenix.Controller, only: [text: 2]
  import Plug.Conn, only: [halt: 1]

  def init(app_var) do
    Application.get_env(:slax, :slack_tokens)
    |> Keyword.get(app_var)
  end

  def call(%Plug.Conn{params: %{"token" => token}} = conn, local_token) do
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
