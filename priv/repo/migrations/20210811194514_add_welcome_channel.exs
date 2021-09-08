defmodule Pb.Repo.Migrations.AddWelcomeChannel do
  use Ecto.Migration

  def change do
    alter(table(:teams)) do
      add(:welcome_channel_slack_id, :string)
    end
  end
end
