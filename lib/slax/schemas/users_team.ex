defmodule Slax.Schemas.UsersTeam do
  @moduledoc """
  UsersTeam Schema
  """
  use Ecto.Schema

  alias Slax.Schemas.Team
  alias Slax.Schemas.User

  schema "users_teams" do
    belongs_to(:team, Team)
    belongs_to(:user, User)

    timestamps()
  end
end
