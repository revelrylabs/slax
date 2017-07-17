defmodule Slax.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :slack_id, :string
      add :github_username, :string
      add :github_access_token, :string

      timestamps
    end

  end
end
