defmodule Slax.Sprint do
  @moduledoc false

  use Slax.Schema

  @type t :: %__MODULE__{}
  schema "sprints" do
    #field(:start_date, :date)
    #field(:end_date, :date)
    belongs_to :project_repo, Slax.ProjectRepo
    field(:issues, {:array, :integer}, default: [])
    field(:milestone_id, :integer)
  end

  @fields ~w(project_repo_id milestone_id issues)a

  @doc false
  def changeset(%Sprint{} = sprint, attrs) do
    sprint
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
