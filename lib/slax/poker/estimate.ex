defmodule Slax.Estimate do
  @moduledoc false

  use Slax.Schema

  @type t :: %__MODULE__{}
  schema "estimates" do
    field(:user, :string)
    field(:value, :integer)

    belongs_to(:round_id, Slax.Round)

    timestamps()
  end
end
