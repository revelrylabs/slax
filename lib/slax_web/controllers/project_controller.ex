defmodule SlaxWeb.ProjectController do
  use SlaxWeb, :controller
  alias Slax.Integrations

  plug(Slax.Plugs.VerifySlackToken, :project)
  plug(Slax.Plugs.VerifyUser)

  alias Slax.Commands.NewProject

  def start(conn, %{"response_url" => response_url, "text" => "new " <> repo}) do
    Task.start_link(__MODULE__, :handle_new_project_request, [
      conn.assigns.current_user.github_access_token,
      repo,
      response_url
    ])

    send_resp(conn, 201, "")
  end

  def start(conn, _) do
    text(conn, """
    *Project commands:*
    /project new <project_name> -- _Creates a new project with the given project name_
    """)
  end

  def handle_new_project_request(github_access_token, repo, response_url) do
    formatted_response =
      NewProject.new_project(String.trim(repo), github_access_token)
      |> NewProject.format_results()

    Integrations.slack().send_message(response_url, %{
      response_type: "in_channel",
      text: formatted_response
    })
  end
end
