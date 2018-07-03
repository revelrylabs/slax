defmodule Slax.Projects do
  use Slax.Context

  alias Slax.{Project, ProjectChannel, ProjectRepo}

  def get_project_for_channel(channel_name) do
    Project
    |> join(:inner, [p], pc in ProjectChannel, pc.project_id == p.id)
    |> where([p, pc], pc.channel_name == ^channel_name)
    |> preload([:repos])
    |> Repo.one()
  end

  def get_repo_for_channel(channel_name) do
    from(
      project_repo in ProjectRepo,
      join: project in assoc(project_repo, :project),
      join: project_channel in assoc(project, :channels),
      where: project_channel.channel_name == ^channel_name,
    )
    |> Repo.one!()
  end
end
