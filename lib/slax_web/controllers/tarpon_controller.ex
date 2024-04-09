defmodule SlaxWeb.TarponController do
  use SlaxWeb, :controller
  alias Slax.Slack

  plug(Slax.Plugs.VerifySlackToken)

  def start(conn, %{
        "command" => command,
        "response_url" => response_url
      }) do
    if Regex.match?(~r{/tarpon}i, command) do
      Slack.send_message(response_url, "🐟")
    end

    send_resp(conn, 200, "")
  end
end
