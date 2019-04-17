defmodule SlaxWeb.BlockerController do
  use SlaxWeb, :controller
  alias Slax.Slack
  alias Slax.Github

  plug(Slax.Plugs.VerifySlackToken, token: :blocker)
  plug(Slax.Plugs.VerifyUser)

  alias Slax.Commands.{GithubCommands}

  def start(conn, %{"response_url" => response_url, "text" => "get-all"}) do
    do_start(
      conn,
      :handle_get_blockers_request,
      [
        conn.assigns.current_user.github_access_token,
        response_url
      ]
    )
  end

  def start(conn, _) do
    text(conn, """
    *Blocker commands:*
    /blocker get-all  -- _Gets all potential blockers for whatever project channel you are calling from_
    """)
  end

  defp do_start(conn, func, args) do
    Task.start_link(__MODULE__, func, args)
    send_resp(conn, 201, "")
  end

  def handle_get_blockers_request(github_access_token, response_url) do
    params = %{
      username: "norzechowski",
      project: "neil-orzechowski",
      repo: "test-repo",
      access_token: github_access_token
    } #TODO: don't hardcode

    formatted_response = 
      Github.fetch_issues(params)
      |> Jason.encode!() #TODO: don't return raw json string

    Slack.send_message(response_url, %{
      response_type: "in_channel",
      text: formatted_response
    })
  end
end
