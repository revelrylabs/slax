defmodule Slax.Event do
  @moduledoc false

  use Slax.Schema

  @type t :: %__MODULE__{}
  schema "events" do
    field(:github_id, :integer)
    field(:number, :integer)
    field(:ord, :string)
    field(:payload, :integer)
    field(:repo, :string)

    timestamps()
  end
end
