defmodule Slax.Channel do
  @moduledoc false
  use Slax.Schema

  @type t :: %__MODULE__{}
  schema "channels" do
    field(:channel_id, :string)
    field(:name, :string)
    field(:disabled, :boolean, default: false)
    belongs_to(:default_project_repo, Slax.ProjectRepo)

    timestamps()
  end

  def changeset(channel, params \\ %{}) do
    channel
    |> cast(params, [:channel_id, :name, :disabled, :default_project_repo_id])
    |> unique_constraint(:channel_id)
  end
end
