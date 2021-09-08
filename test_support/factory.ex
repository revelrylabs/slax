defmodule Slax.Factory do
  use ExMachina.Ecto, repo: Slax.Repo
  use Slax.ShoutoutFactory
  use Slax.TeamFactory
  use Slax.UserFactory

  def users_team_factory do
    %Slax.Schemas.UsersTeam{
      team: build(:team),
      user: build(:user)
    }
  end
end
