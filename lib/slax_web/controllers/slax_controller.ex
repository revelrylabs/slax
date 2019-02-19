defmodule SlaxWeb.SlaxController do
  use SlaxWeb, :controller
  alias Slax.{Commander, Integrations}

  plug(Slax.Plugs.VerifySlackToken, token: :slax)
  plug(Slax.Plugs.VerifyUser)

  def start(conn, %{"response_url" => response_url, "text" => command}) do
    do_start(
      conn,
      :handle_command,
      [
        %Slax.Commands.Context{
          user: Map.get(conn.assigns, :current_user)
        },
        OptionParser.split(command),
        response_url
      ]
    )
  end

  defp do_start(conn, func, args) do
    Task.start_link(__MODULE__, func, args)
    send_resp(conn, 201, "")
  end

  def handle_command(context = %Slax.Commands.Context{}, command, response_url) do
    response = Commander.run(context, command)

    Integrations.slack().send_message(response_url, %{
      response_type: "in_channel",
      text: response
    })
  end
end
