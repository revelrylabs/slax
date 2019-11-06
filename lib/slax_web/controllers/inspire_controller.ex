defmodule SlaxWeb.InspireController do
  use SlaxWeb, :controller
  alias Slax.Slack

  plug(Slax.Plugs.VerifySlackToken, token: :inspire)

  def start(conn, %{"channel_name" => channel_name}) do

    %HTTPoison.Response{body: body} = HTTPoison.get!("https://inspirobot.me/api?generate=true")

    Slack.post_message_to_channel(%{
      channel_name: channel_name,
      text: body,
    })

    send_resp(conn, 200, "")
  end
end
