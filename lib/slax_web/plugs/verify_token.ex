defmodule Slax.Plugs.VerifySlackToken do
  import Phoenix.Controller, only: [text: 2]
  import Plug.Conn, only: [halt: 1]

  def init(options) do
    options
  end

  def call(%Plug.Conn{req_headers: req_headers} = conn, params) do
    header_map = Enum.into(req_headers, %{})
    %{"x-slack-request-timestamp" => timestamp, "x-slack-signature" => slack_sig} = header_map

    body = SlaxWeb.CacheBodyReader.read_cached_body(conn)

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
  end

  def call(conn, _) do
    conn
  end
end
