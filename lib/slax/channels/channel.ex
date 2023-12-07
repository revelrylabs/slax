defmodule Slax.Channel do
  use Slax.Schema

  @type t :: %__MODULE__{}
  schema "channels" do
    field(:channel_id, :string)
    field(:name, :string)
    field(:disabled, :boolean, default: false)

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:id, :name, :disabled])
  end
end
