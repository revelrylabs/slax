defmodule SlaxWeb.ProjectController do
  use SlaxWeb, :controller
  alias Slax.Integrations

  plug(Slax.Plugs.VerifySlackToken, app_var: :project)
  plug(Slax.Plugs.VerifyUser)

  alias Slax.Commands.{NewProject, ReuseableStories, GithubCommands}

  def start(conn, %{"response_url" => response_url, "text" => "new " <> repo}) do
    do_start(
      conn,
      :handle_new_project_request,
      [
        conn.assigns.current_user.github_access_token,
        repo,
        response_url
      ]
    )
  end

  def start(conn, %{"response_url" => response_url, "text" => "add-reusable-stories " <> repo}) do
    do_start(
      conn,
      :handle_reuseable_stories_request,
      [
        conn.assigns.current_user.github_access_token,
        repo,
        response_url
      ]
    )
  end

  def start(conn, _) do
    text(conn, """
    *Project commands:*
    /project new <project_name> -- _Creates a new project with the given project name_
    /project add-reusable-stories <repo> -- _Adds reusable stories to the given repo_
    """)
  end

  defp do_start(conn, func, args) do
    Task.start_link(__MODULE__, func, args)
    send_resp(conn, 201, "")
  end

  def handle_new_project_request(github_access_token, repo, response_url) do
    formatted_response =
      NewProject.new_project(String.trim(repo), github_access_token)
      |> GithubCommands.format_results()

    Integrations.slack().send_message(response_url, %{
      response_type: "in_channel",
      text: formatted_response
    })
  end

  def handle_reuseable_stories_request(github_access_token, repo, response_url) do
    formatted_response =
      ReuseableStories.reuseable_stories(String.trim(repo), github_access_token)
      |> GithubCommands.format_results()

    Integrations.slack().send_message(response_url, %{
      response_type: "in_channel",
      text: formatted_response
    })
  end
end
