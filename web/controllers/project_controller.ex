defmodule Slax.ProjectController do
  use Slax.Web, :controller

  @org_name Application.get_env(:slax, :github)[:org_name]
  @reuseable_stories_repo Application.get_env(:slax, :reusable_stories)
  @story_paths Application.get_env(:slax, :reusable_stories_paths)

  plug Slax.Plugs.VerifySlackToken, :project
  plug Slax.Plugs.VerifyUser

  def start(conn, %{"text" => "new " <> repo}) do
    formatted_response = Slax.Project.new_project(@org_name, repo, conn.assigns.current_user.github_access_token, @reuseable_stories_repo, @story_paths)
    |> Slax.project.format_results

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
