defmodule Slax.ProjectRepos do
  use Slax.Context

  alias Slax.{ProjectRepo, ProjectChannel}

  def get_blockerbot_repos() do
    ProjectRepo
    |> join(:left, [pr], pc in ProjectChannel, on: pr.project_id == pc.project_id)
    |> where([pr, pc], pc.blockerbot_on)
    |> select([pr, pc], %{
      repo_name: pr.repo_name,
      org_name: pr.org_name,
      channel_name: pc.channel_name
    })
    |> Repo.all()
  end
end
