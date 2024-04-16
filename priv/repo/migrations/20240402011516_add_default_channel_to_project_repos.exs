defmodule Slax.Repo.Migrations.AddDefaultChannelToProjectRepos do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add(:default_project_repo_id, references(:project_repos))
    end
  end
end
