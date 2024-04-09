defmodule SlaxWeb.InspireController do
  use SlaxWeb, :controller
  alias Slax.Slack

  plug(Slax.Plugs.VerifySlackToken, token: :inspire)

  def start(conn, %{"text" => text, "channel_name" => channel_name}) do
    if Regex.match?(~r/inspire/i, text) do
      %HTTPoison.Response{body: inspiration} =
        HTTPoison.get!("https://inspirobot.me/api?generate=true")

      Slack.post_message_to_channel(inspiration, channel_name)
    end

    send_resp(conn, 200, "")
  end
end
