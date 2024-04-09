defmodule Slax.Factory do
  alias Slax.{User, ProjectRepo, Project, ProjectChannel, Repo, Channel}
  use ExMachina.Ecto, repo: Repo

  def user_factory do
    %User{
      slack_id: "slack",
      github_username: "testuser",
      github_access_token: "token"
    }
  end

  def project_factory do
    %Project{
      name: "hit song"
    }
  end

  def project_repo_factory do
    %ProjectRepo{
      project: build(:project),
      repo_name: "girl u know its true",
      org_name: "milivanili",
      token: "token",
      expiration_date: DateTime.utc_now()
    }
  end

  def project_channel_factory do
    %ProjectChannel{
      project: build(:project),
      channel_name: "testchannel",
      webhook_token: "token"
    }
  end

  def channel_factory do
    %Channel{
      channel_id: "ABCDEFG",
      name: "test",
      disabled: false
    }
  end
end
