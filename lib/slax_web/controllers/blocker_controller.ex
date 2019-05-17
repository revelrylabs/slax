defmodule SlaxWeb.BlockerController do
  use SlaxWeb, :controller

  plug(Slax.Plugs.VerifySlackToken, token: :blocker)
  plug(Slax.Plugs.VerifyUser)

  alias Slax.{EventSink, Github, Slack}
  alias Slax.Commands.{GithubCommands, Latency}

  @moduledoc """
  Entry point to interact with blockerbot functionality.
  Eventually we may want to think about adding slash commands to handle various configuration tasks, such as:
  > /blocker in-progress-min=2 #Set the mininum threshold for how long something is a blocker to 2 days
  > /blocker turn-on/off #Turn on/off the blockerbot for a particular channel and/or project
  """

  def start(conn, %{"response_url" => response_url, "text" => "latency", "channel_name" => channel_name}) do
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

  def start(conn, _) do
    text(conn, """
    *Blocker commands:*
    /blocker latency  -- _Get issues for this channel which have not updated lately_
    """)
  end

  defp do_start(conn, func, args) do
    Task.start_link(__MODULE__, func, args)
    send_resp(conn, 201, "")
  end

  def handle_get_blockers_request(github_access_token, response_url, channel_name) do
    repo_names =
      Slax.ProjectChannel
      |> from()
      |> where([pc], pc.channel_name == ^channel_name)
      |> join(:inner, [pc], p in assoc(pc, :project))
      |> select([_, pc], pc.name)
      |> Repo.all()

    respond_for_repos(repo_names, github_access_token, response_url)
  end

  defp respond_for_repos([], _, response_url) do
    Slack.send_message(response_url, %{
      response_type: "in_channel",
      text: "No repos for this channel."
    })
  end
  defp respond_for_repos(repo_names, github_access_token, response_url) do
    Enum.each(repo_names, fn repo_name ->
      respond_for_repo(repo_name, github_access_token, response_url)
    end)
  end

  defp respond_for_repo(repo_name, github_access_token, response_url) do
    org_name =  Application.get_env(:slax, Slax.Github)[:org_name]

    formatted_response =
      Latency.text_for_org_and_repo(org_name, repo_name, github_access_token)

    Slack.send_message(response_url, %{
      response_type: "in_channel",
      text: formatted_response
    })
  end
end
