defmodule Slax.Projects do
  use Slax.Context

  alias Slax.{Project, ProjectChannel}

  def get_project_for_channel(channel_name) do
    Project
    |> join(:inner, [p], pc in ProjectChannel, on: pc.project_id == p.id)
    |> where([p, pc], pc.channel_name == ^channel_name)
    |> preload([:repos])
    |> Repo.one()
  end

  def create(project) do
    project
    |> Project.changeset()
    |> Repo.insert()
  end

  def get_or_create_by_name(project_name) do
    case get_by_name(project_name) do
      nil ->
        create(%{name: project_name})

      project ->
        {:ok, project}
    end
  end

  def get_by_name(project_name) do
    Repo.get_by(Project, name: project_name)
  end

  def get_all() do
    Project
    |> Repo.all()
  end
end
