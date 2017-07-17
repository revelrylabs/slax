defmodule Slax.Repo.Migrations.AddIndexToSlackId do
  use Ecto.Migration

  def change do
    create index(:users, [:slack_id], unique: true)
  end
end
