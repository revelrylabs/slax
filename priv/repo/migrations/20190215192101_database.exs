defmodule Slax.Repo.Migrations.Database do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:estimates) do
      add(:user, :string)
      add(:value, :integer)
      add(:round_id, :integer)
      add(:created_at, :utc_datetime, null: false)
      add(:updated_at, :utc_datetime, null: false)
      add(:reason, :string)
    end

    create_if_not_exists table(:events) do
      add(:repo, :string)
      add(:org, :string)
      add(:number, :integer)
      add(:payload, :json)
      add(:github_id, :integer)
      add(:created_at, :utc_datetime, null: false)
      add(:updated_at, :utc_datetime, null: false)
    end

    create_if_not_exists(index(:events, ["number"], name: "index_events_on_number"))
    create_if_not_exists(index(:events, ["org"], name: "index_events_on_org"))
    create_if_not_exists(index(:events, ["repo"], name: "index_events_on_repo"))

    create_if_not_exists table(:health_calculations) do
      add(:org, :string)
      add(:repo, :string)
      add(:start_dt, :utc_datetime)
      add(:end_dt, :utc_datetime)
      add(:bugs_count, :integer)
      add(:bugs_closed_fast_count, :integer)
      add(:features_count, :integer)
      add(:features_closed_fast_count, :integer)
      add(:created_at, :utc_datetime)
      add(:updated_at, :utc_datetime)
    end

    create_if_not_exists table(:people) do
      add(:github_username, :string)
      add(:slack_username, :string)
      add(:created_at, :utc_datetime, null: false)
      add(:updated_at, :utc_datetime, null: false)
    end

    create_if_not_exists table(:project_channels) do
      add(:project_id, :integer)
      add(:channel_name, :string)
      add(:created_at, :utc_datetime, null: false)
      add(:updated_at, :utc_datetime, null: false)
      add(:webhook_token, :string)
    end

    create_if_not_exists(
      index(:project_channels, ["channel_name"], name: "index_project_channels_on_channel_name")
    )

    create_if_not_exists table(:project_repos) do
      add(:project_id, :integer, null: false)
      add(:org_name, :string, null: false)
      add(:repo_name, :string, null: false)
      add(:created_at, :utc_datetime, null: false)
      add(:updated_at, :utc_datetime, null: false)
    end

    create_if_not_exists table(:projects) do
      add(:name, :string)
      add(:created_at, :utc_datetime, null: false)
      add(:updated_at, :utc_datetime, null: false)
    end

    create_if_not_exists table(:rounds) do
      add(:revealed, :boolean)
      add(:value, :integer)
      add(:issue, :string)
      add(:channel, :string)
      add(:created_at, :utc_datetime, null: false)
      add(:updated_at, :utc_datetime, null: false)
      add(:closed, :boolean)
      add(:response_url, :string)
    end

    create_if_not_exists table(:sprints) do
      add(:project_repo_id, references(:project_repos, on_delete: :nothing))
      add(:milestone_id, :integer, null: false)
      add(:issues, {:array, :integer}, default: [], null: false)
    end

    create_if_not_exists(index(:sprints, ["milestone_id"], name: "index_sprints_on_milestone_id"))

    create_if_not_exists(
      index(:sprints, ["project_repo_id"], name: "index_sprints_on_project_repo_id")
    )

    create_if_not_exists table(:users) do
      add(:slack_id, :string)
      add(:github_username, :string)
      add(:github_access_token, :string)
    end
  end
end
