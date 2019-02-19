defmodule Slax.Factory do
  alias Slax.{User, Repo}
  use ExMachina.Ecto, repo: Repo

  def user_factory do
    %User{
      slack_id: "slack",
      github_username: "testuser",
      github_access_token: "token"
    }
  end
end
