defmodule Slax.Schemas.Team do
  @moduledoc """
  Team Schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Slax.Schemas.User
  alias Slax.Schemas.UsersTeam

  schema "teams" do
    field(:name, :string)
    field(:slack_id, :string)
    field(:token, Slax.Schemas.Types.Secret)
    field(:avatar, :string)
    field(:onboarded_at, :utc_datetime)
    field(:send_welcome_message, :boolean)
    field(:welcome_channel_slack_id, :string)
    many_to_many(:users, User, join_through: UsersTeam)

    timestamps()
  end

  def changeset(team, attrs) do
    team
    |> cast(attrs, [
      :avatar,
      :name,
      :onboarded_at,
      :send_welcome_message,
      :slack_id,
      :token,
      :welcome_channel_slack_id
    ])
    |> validate_required([:name, :slack_id, :token])
  end
end
