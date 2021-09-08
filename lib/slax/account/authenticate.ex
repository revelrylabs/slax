defmodule Slax.Account.Authenticate do
  @moduledoc """
  This module contains the authentication for the Slax.Account module.
  """
  alias Ecto.Multi

  alias Slax.Repo
  alias Slax.Schemas.Team
  alias Slax.Schemas.User
  alias Slax.Schemas.UsersTeam
  alias Slax.Teams
  alias Slax.Users

  @doc false
  def authenticate(attrs) do
    Multi.new()
    |> Multi.put(:attrs, attrs)
    |> Multi.insert_or_update(:team, &insert_or_update_team/1)
    |> Multi.insert_or_update(:user, &insert_or_update_user/1)
    |> Multi.insert_or_update(:users_team, &insert_or_update_users_team/1)
    |> Multi.run(:new_user, &fetch_user/2)
    |> Repo.transaction()
  end

  defp fetch_user(_, %{user: %{id: id}}) do
    {:ok, Slax.Users.get_user(id: id)}
  end

  defp insert_or_update_team(%{attrs: %{team: attrs}}) do
    team = Teams.get_team(slack_id: attrs.slack_id) || %Team{}
    Team.changeset(team, attrs)
  end

  defp insert_or_update_user(%{attrs: %{user: attrs}}) do
    user = Users.get_user(slack_id: attrs.slack_id) || %User{}
    User.changeset(user, attrs)
  end

  defp insert_or_update_users_team(%{team: team, user: user}) do
    users_team = Repo.get_by(UsersTeam, team_id: team.id, user_id: user.id) || %UsersTeam{}
    Ecto.Changeset.change(users_team, %{team_id: team.id, user_id: user.id})
  end
end
