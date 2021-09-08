defmodule Slax.Teams.Delete do
  @moduledoc """
  Delete a team.
  """
  alias Ecto.Multi

  alias Slax.Repo
  alias Slax.Teams
  alias Slax.Users

  @doc false
  def delete_team(team_id) do
    Multi.new()
    |> Multi.delete(:team, Teams.get_team(id: team_id))
    |> Multi.merge(&delete_orphaned_users/1)
    |> Repo.transaction()
  end

  defp delete_orphaned_users(_) do
    users = Users.list_users(orphans: true)

    Enum.reduce(users, Multi.new(), fn user, multi ->
      step = String.to_atom("delete_user_#{user.id}")
      Multi.delete(multi, step, user)
    end)
  end
end
