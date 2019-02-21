defmodule SlaxWeb.SlaxController do
  use SlaxWeb, :controller
  alias Slax.{Commander, Slack}

  plug(Slax.Plugs.VerifySlackToken, token: :slax)
  plug(Slax.Plugs.VerifyUser)

  def start(conn, %{"response_url" => response_url, "text" => command}) do
    context = %Slax.Commands.Context{
      user: Map.get(conn.assigns, :current_user)
    }

    command_args = OptionParser.split(command)

    Task.start_link(fn ->
      response = Commander.run(context, command_args)

      Slack.send_message(response_url, %{
        response_type: "in_channel",
        text: response
      })
    end)

    send_resp(conn, 201, "")
  end
end
