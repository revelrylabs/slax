defmodule Slax.User do
  @moduledoc false
  use SlaxWeb, :model

  schema "users" do
    field(:slack_id, :string)
    field(:github_username, :string)
    field(:github_access_token, :string)
  end

  @required_fields [:slack_id]
  @optional_fields [:github_username, :github_access_token]

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, @required_fields ++ @optional_fields)
  end
end
