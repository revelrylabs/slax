defmodule Slax.Repo.Migrations.ModifyRoundIdToReference do
  use Ecto.Migration

  def change do
    alter table(:estimates) do
      modify(:round_id, references(:rounds, on_delete: :nothing))
    end
  end
end
