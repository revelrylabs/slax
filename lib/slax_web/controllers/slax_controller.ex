defmodule SlaxWeb.SlaxController do
  use SlaxWeb, :controller
  alias Slax.{Commander, Integrations}

  plug(Slax.Plugs.VerifySlackToken, token: :slax)
  # plug(Slax.Plugs.VerifyUser)

  def start(conn, %{"response_url" => response_url, "text" => command}) do
    do_start(
      conn,
      :handle_command,
      [
        Map.get(conn.assigns, :current_user),
        command,
        response_url
      ]
    )
  end

  defp do_start(conn, func, args) do
    Task.start_link(__MODULE__, func, args)
    send_resp(conn, 201, "")
  end

  def handle_command(user, command, response_url) do
    response = Commander.run(user, command)

    Integrations.slack().send_message(response_url, %{
      response_type: "in_channel",
      text: response
    })
  end
end
