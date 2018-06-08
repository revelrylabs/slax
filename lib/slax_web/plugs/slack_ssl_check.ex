defmodule SlaxWeb.Plugs.SlackSSLCheck do
  @moduledoc """
  Respond to requests from Slack to check for SSL support
  """

  import Phoenix.Controller, only: [text: 2]
  import Plug.Conn, only: [halt: 1]

  def init(_) do
    :ok
  end

  def call(%Plug.Conn{params: %{"ssl_check" => "1"}} = conn, _) do
    conn
    |> text("")
    |> halt()
  end

  def call(conn, _) do
    conn
  end
end
