defmodule SlaxWeb.BlockerbotController do
  use SlaxWeb, :controller

  alias Slax.{ProjectRepos, Github}


def start(conn, _params) do
  repos = ProjectRepos.get_repos()
  repos
    |> Enum.map(fn repo ->
    Github.fetch_issues(repo)
    end)
  text(conn, "ok")
end



# def start(conn, %{"channel" => channel_name}) do
#   case Projects.get_project_for_channel(channel_name) do
#     nil ->
#       text(conn, "A project could not be found for this channel.")

#     project ->
#       repo = List.first(project.repos)

#       params = %{
#         repo_name:
#         org_name:
#         channel_name:
#         webhook:

#       }

# end

# get webhook and other needed infor from db to make github request
# get issues of project


end
