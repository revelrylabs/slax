defmodule SlaxWeb.TarponController do
  use SlaxWeb, :controller
  alias Slax.Integrations

  plug(Slax.Plugs.VerifySlackToken, app_var: :tarpon)

  def start(conn, %{"text" => text, "channel_id" => channel_id, "timestamp" => timestamp}) do
    if Regex.match?(~r/tarpon/i, text) do
      Integrations.slack().add_reaction(%{
        name: "fish",
        channel_id: channel_id,
        timestamp: timestamp
      })
    end

    send_resp(conn, 200, "")
  end
end
