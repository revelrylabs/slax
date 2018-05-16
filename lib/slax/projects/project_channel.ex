defmodule Slax.ProjectChannel do
  @moduledoc false

  use Slax.Schema

  @type t :: %__MODULE__{}
  schema "project_channels" do
    belongs_to(:project, Slax.Project)
    field(:channel_name, :string)
    field(:webhook_token, :string)

    timestamps()
  end
end
