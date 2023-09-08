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
end
