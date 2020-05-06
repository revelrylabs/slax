defmodule Slax.Poker.Estimate do
  @moduledoc false

  use Slax.Schema

  @type t :: %__MODULE__{}
  schema "estimates" do
    field(:user, :string)
    field(:value, :integer)
    field(:reason, :string)

    belongs_to(:round, Slax.Poker.Round)

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:user, :value, :reason, :round_id])
  end
end
