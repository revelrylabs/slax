defmodule Slax.Sprint do
  @moduledoc false

  use Slax.Schema

  @type t :: %__MODULE__{}
  schema "sprints" do
    belongs_to(:project_repo, Slax.ProjectRepo)
    belongs_to(:creator, Slax.User)
    field(:issues, {:array, :integer}, default: [])
    field(:milestone_id, :integer)
    field(:message, :string)
    field(:committed, :boolean, default: false)
    field(:week, :integer)
    field(:year, :integer)
  end

  @required_fields ~w(project_repo_id creator_id milestone_id issues week year)a
  @fields @required_fields ++ ~w(message committed)a

  @doc false
  def changeset(%Sprint{} = sprint, attrs) do
    sprint
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
end
