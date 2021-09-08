defmodule Slax.Schemas.ShoutoutReceiver do
  @moduledoc """
  UsersShoutout Schema
  """
  use Ecto.Schema

  alias Slax.Schemas.Shoutout
  alias Slax.Schemas.User

  schema "shoutout_receivers" do
    belongs_to(:shoutout, Shoutout)
    belongs_to(:receiver, User, foreign_key: :user_id)
  end
end
