defmodule Slax.Repo.Migrations.AddChannelsTable do
  use Ecto.Migration

  def change do
    create table(:channels) do
      add(:channel_id, :string)
      add(:name, :string)
      add(:disabled, :boolean, default: false)
      add(:created_at, :utc_datetime, null: false)
      add(:updated_at, :utc_datetime, null: false)
    end
  end
end
