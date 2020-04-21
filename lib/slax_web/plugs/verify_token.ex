defmodule Slax.Plugs.VerifySlackToken do
  import Phoenix.Controller, only: [text: 2]
  import Plug.Conn, only: [halt: 1, get_req_header: 2]

  def init(options) do
    options
  end

  def call(conn, %{"token" => token}) do
    with [slack_sig] <- get_req_header(conn, "x-slack-signature"),
         [timestamp] <- get_req_header(conn, "x-slack-request-timestamp"),
         body <- SlaxWeb.CacheBodyReader.read_cached_body(conn) do
      base_sig = ~s{v0:#{timestamp}:#{body}}

      hashed_sig =
        :crypto.hmac(
          :sha256,
          Application.get_env(:slax, Slax.Slack)[:api_signing_secret],
          base_sig
        )
        |> Base.encode16()
        |> String.downcase()

      my_sig = ~s{v0=#{hashed_sig}}

      case my_sig == slack_sig do
        true ->
          conn

        false ->
          text(conn, "Invalid slack signing secret.") |> halt
      end
    else
      _token when token == :auth ->
        conn

      _ ->
        "Invalid params"
    end
  end

  def call(conn, _) do
    conn
  end
end
