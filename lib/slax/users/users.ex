defmodule Slax.Users do
  import Ecto.{Query, Changeset}, warn: false
  alias Slax.{Repo, User}

  def get_user(slack_id) do
    Repo.get_by(User, slack_id: slack_id)
  end

  def create_or_update_user(slack_id, attrs) do
    case Repo.get_by(User, slack_id: slack_id) do
      nil -> %User{slack_id: slack_id}
      user -> user
    end
    |> User.changeset(attrs)
    |> Repo.insert_or_update()
  end
end
