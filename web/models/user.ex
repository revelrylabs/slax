defmodule Slax.User do
  use Slax.Web, :model

  schema "users" do
    field :slack_id, :string
    field :github_username, :string
    field :github_access_token, :string

    timestamps
  end

  @required_fields ~w(slack_id)
  @optional_fields ~w(github_username github_access_token)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
