defmodule Pb.Repo.Migrations.AddSendWelcomeMessage do
  use Ecto.Migration

  def change do
    alter(table(:teams)) do
      add(:send_welcome_message, :boolean, default: false)
    end
  end
end
