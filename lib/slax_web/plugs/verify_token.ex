defmodule Slax.Plugs.VerifySlackToken do
  import Phoenix.Controller, only: [text: 2]
  import Plug.Conn, only: [halt: 1]

  def init(options) do
    options
  end

  def call(%Plug.Conn{params: %{"token" => token}} = conn, token: app_var) do
    slax_config = Application.get_env(:slax, Slax.Slack, [])
    tokens = Keyword.get(slax_config, :tokens, [])
    local_token = Keyword.get(tokens, app_var)

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
