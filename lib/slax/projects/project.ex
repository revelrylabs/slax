defmodule Slax.Project do
  @moduledoc false

  use Slax.Schema

  @type t :: %__MODULE__{}
  schema "projects" do
    field(:name, :string)
    has_many(:repos, Slax.ProjectRepo)

    timestamps()
  end

  def changeset(params \\ %{}) do
    cast(%__MODULE__{}, params, [:name])
  end
end
