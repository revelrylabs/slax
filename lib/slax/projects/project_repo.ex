defmodule Slax.ProjectRepo do
  @moduledoc false

  use Slax.Schema

  @type t :: %__MODULE__{}
  schema "project_repos" do
    belongs_to(:project, Slax.Project)
    field(:org_name, :string)
    field(:repo_name, :string)

    timestamps()
  end
end
