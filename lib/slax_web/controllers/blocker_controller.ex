defmodule SlaxWeb.BlockerController do
  use SlaxWeb, :controller
  alias Slax.Slack
  alias Slax.Github

  plug(Slax.Plugs.VerifySlackToken, token: :blocker)
  plug(Slax.Plugs.VerifyUser)

  alias Slax.Commands.{GithubCommands}

  # TODO: may want to think about repurposing this slash command to handle configuration of the  daily blocker bot messages
  # e.g. /blocker org/repo 9:00AM
  # /blocker in-progress-min=24
  # etc.
  # would want to store configurations in db

  def start(conn, %{"response_url" => response_url, "text" => "get-all-issues", "channel_name" => channel_name}) do
    do_start(
      conn,
      :handle_get_blockers_request,
      [
        conn.assigns.current_user.github_access_token,
        response_url, 
        channel_name
      ]
    )
  end

  def start(conn, %{ "text" => "init" <> scheduled_time, "channel_name" => channel_name}) do
    do_start(
      conn,
      :handle_get_blockers_init_request,
      [
        conn.assigns.current_user.github_access_token,
        channel_name, 
        scheduled_time
      ]
    )
  end

  def start(conn, _) do
    text(conn, """
    *Blocker commands:*
    /blocker get-all-issues  -- _Gets all potential blockers for whatever project channel (=repo) you are calling from_
    """)
  end

  defp do_start(conn, func, args) do
    Task.start_link(__MODULE__, func, args)
    send_resp(conn, 201, "")
  end

  def handle_get_blockers_request(github_access_token, response_url, channel_name) do
    params = %{
      repo: channel_name,
      access_token: github_access_token,
      org: Application.get_env(:slax, Slax.Github)[:org_name]
    } 
      
    formatted_response = 
      Github.fetch_issues(params)
      |> GithubCommands.format_issues()

    Slack.send_message(response_url, %{
      response_type: "in_channel",
      text: formatted_response
    })
  end

  #test function, can delete
  def handle_get_blockers_init_request(github_access_token, channel_name, scheduled_time) do
    # TODO: save to db
    # TODO: schedule a task 
    formatted_response = "Blocker bot has been scheduled to run at #{scheduled_time}"
 
    Slack.post_message_to_channel(%{
      text: formatted_response,
      channel_name: "#"<>channel_name
    })
  end

end
