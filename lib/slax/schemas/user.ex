defmodule Slax.Schemas.User do
  @moduledoc """
  User Schema
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Slax.Schemas.Shoutout
  alias Slax.Schemas.Team

  schema "users" do
    field(:name, :string)
    field(:avatar, :string)
    field(:slack_id, :string)
    field(:token, Slax.Schemas.Types.Secret)
    many_to_many(:teams, Team, join_through: "users_teams")
    many_to_many(:shoutouts, Shoutout, join_through: "shoutout_receivers")

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :slack_id, :avatar, :token])
    |> validate_required([:slack_id])
    |> cast_assoc(:teams)
    |> cast_assoc(:shoutouts)
  end
end
