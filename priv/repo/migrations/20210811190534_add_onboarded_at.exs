defmodule Pb.Repo.Migrations.AddOnboardedAt do
  use Ecto.Migration

  def change do
    alter(table(:teams)) do
      add(:onboarded_at, :utc_datetime)
    end
  end
end
