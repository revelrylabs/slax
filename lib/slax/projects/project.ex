defmodule Slax.Project do
  @moduledoc false

  use Slax.Schema

  @type t :: %__MODULE__{}
  schema "projects" do
    field(:name, :string)

    timestamps()
  end
end

