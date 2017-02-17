defmodule Slax.ProjectController do
  use Slax.Web, :controller

  plug Slax.Plugs.VerifySlackToken, :project
  plug Slax.Plugs.VerifyUser

  def start(conn, %{"text" => "new " <> repo}) do
    formatted_response = Slax.Project.new_project(String.trim(repo), conn.assigns.current_user.github_access_token)
    |> Slax.Project.format_results

    json conn, %{
      response_type: "in_channel",
      text: formatted_response
    }
  end

  def start(conn, _) do
    text conn, """
    *Project commands:*
    /project new <project_name>
    """
  end
end
