defmodule Slax.ProjectRepo do
  @moduledoc false

  use Slax.Schema

  @type t :: %__MODULE__{}
  schema "project_repos" do
    belongs_to(:project, Slax.Project)
    field(:org_name, :string)
    field(:repo_name, :string)
    field(:token, :string)
    field(:expiration_date, :date)

    timestamps()
  end

  def changeset(params \\ %{}) do
    cast(%__MODULE__{}, params, [:org_name, :repo_name, :project_id])
  end

  def token_changeset(project_repo, token, expiration_date) do
    change(project_repo, %{token: token, expiration_date: expiration_date})
  end
end
