defmodule Slax.ProjectController do
  use Slax.Web, :controller

  plug Slax.Plugs.VerifySlackToken, :project
  plug Slax.Plugs.VerifyUser

  def start(conn, %{"text" => ""}) do
    text conn, """
    *New project commands:*
    /new-project <project_name>
    """
  end

  def start(conn, %{"text" => text}) do
    formatted_response = Slax.Project.new_project(text, conn.assigns.current_user.github_access_token)
    |> Slax.project.format_results

    json conn, %{
      response_type: "in_channel",
      text: formatted_response
    }
  end
end
