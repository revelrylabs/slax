defmodule Slax.Schemas.Shoutout do
  @moduledoc """
  Shoutout Schema
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Slax.Schemas.ShoutoutReceiver
  alias Slax.Schemas.Team
  alias Slax.Schemas.User

  schema "shoutouts" do
    field(:message, :string)
    field(:channel, :string)
    belongs_to(:sender, User)
    belongs_to(:team, Team)
    many_to_many(:receivers, User, join_through: ShoutoutReceiver, on_delete: :delete_all)

    timestamps()
  end

  def changeset(shoutout, attrs) do
    shoutout
    |> cast(attrs, [:message, :channel])
    |> cast_assoc(:sender)
    |> cast_assoc(:team)
    |> validate_required([:message, :sender_id])
  end
end
