defmodule Pb.Repo.Migrations.AddShoutouts do
  use Ecto.Migration

  def change do
    create(table(:teams)) do
      add(:name, :string)
      add(:slack_id, :string)
      add(:avatar, :string)
      add(:token, :binary)
      timestamps()
    end

    create(table(:users)) do
      add(:name, :string)
      add(:slack_id, :string)
      add(:avatar, :string)
      add(:token, :binary)
      timestamps()
    end

    create(table(:users_teams)) do
      add(:team_id, references(:teams, on_delete: :delete_all))
      add(:user_id, references(:users, on_delete: :delete_all))
      timestamps()
    end

    create(index(:users, [:slack_id], unique: true))
    create(index(:teams, [:slack_id], unique: true))
    create(index(:users_teams, [:user_id, :team_id], unique: true))
  end
end
