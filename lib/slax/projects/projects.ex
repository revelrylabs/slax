defmodule Slax.Projects do
  use Slax.Context

  alias Slax.{Project, ProjectChannel}

  def get_project_for_channel(channel_name) do
    Project
    |> join(:inner, [p], pc in ProjectChannel, pc.project_id == p.id)
    |> where([p, pc], pc.channel_name == ^channel_name)
    |> Repo.one()
  end
end
