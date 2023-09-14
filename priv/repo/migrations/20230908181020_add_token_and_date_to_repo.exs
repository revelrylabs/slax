defmodule Slax.Repo.Migrations.AddTokenAndDateToRepo do
  use Ecto.Migration

  def change do
    Application.ensure_started(:ssl)
    alter table(:project_repos) do
      add(:token, :string)
      add(:expiration_date, :date)
    end
  end
end
