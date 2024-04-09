defmodule Slax.Poker.Round do
  @moduledoc false

  use Slax.Schema

  @type t :: %__MODULE__{}
  schema "rounds" do
    field(:channel, :string)
    field(:closed, :boolean, default: false)
    field(:issue, :string)
    field(:response_url, :string)
    field(:revealed, :boolean, default: false)
    field(:value, :integer)

    has_many(:estimates, Slax.Poker.Estimate)

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:channel, :closed, :issue, :response_url, :revealed, :value])
  end
end
