defmodule SlaxWeb.ProjectController do
  use SlaxWeb, :controller
  alias Slax.Integrations

  plug(Slax.Plugs.VerifySlackToken, :project)
  plug(Slax.Plugs.VerifyUser)

  alias Slax.Commands.{NewProject, ProjectVelocity}

  def start(conn, %{"response_url" => response_url, "text" => "new " <> repo}) do
    Task.start_link(__MODULE__, :handle_new_project_request, [
      conn.assigns.current_user.github_access_token,
      repo,
      response_url
    ])

    send_resp(conn, 201, "")
  end

  def start(conn, %{
        "channel_name" => channel_name,
        "response_url" => response_url,
        "text" => "velocity"
      }) do
    Task.start_link(__MODULE__, :handle_velocity_request, [
      channel_name,
      response_url
    ])

    send_resp(conn, 201, "")
  end

  def start(conn, _) do
    text(conn, """
    *Project commands:*
    /project new <project_name> -- _Creates a new project with the given project name_
    /project velocity <week> -- _Gets the velocity for the current week for the project_
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

  def handle_velocity_request(channel_name, response_url) do
    project_repo = Slax.Projects.get_project_for_channel(channel_name)

    result =
      ProjectVelocity.calculate_sprint_velocity(
        project_repo.org_name,
        project_repo.repo_name,
        1,
        DateTime.utc_now()
      )

    formatted_response =
      case result do
        {:ok, data} ->
          """
          Points in Sprint: #{data.sprint.points}
          Points Completed: #{data.completed.points}
          """

        {:error, _} ->
          "Unable to calculate velocity"
      end

    Integrations.slack().send_message(response_url, %{
      response_type: "in_channel",
      text: formatted_response
    })
  end
end
