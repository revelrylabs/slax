defmodule Slax.Channel do
  use Slax.Schema

  @type t :: %__MODULE__{}
  schema "channels" do
    field(:channel_id, :string)
    field(:name, :string)
    field(:disabled, :boolean, default: false)

    timestamps()
  end

  def changeset(channel, params \\ %{}) do
    channel
      |> cast(params, [:channel_id, :name, :disabled])
      |> unique_constraint(:channel_id)
  end
end
