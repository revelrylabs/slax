defmodule Slax.Sprint do
  @moduledoc false

  require Logger
  use Ecto.Schema
  import Ecto.Changeset, warn: false
  alias Comeonin.Bcrypt

  @type t :: %__MODULE__{}
  schema "sprints" do
    field(:start_date, Ecto.Date)
    field(:end_date, Ecto.Date)
    field(:project_id, :integer)
    field(:milestone_url, :string)

    timestamps()
  end

  def create_changeset(model, params \\ %{}) do
    required_fields = [
      :email,
      :new_password,
      :new_password_confirmation,
      :first_name,
      :last_name,
      :phone_number,
      :role_id
    ]

    optional_fields = [
      :cdl_number,
      :company_name,
      :device_token,
      :confirmation_code,
      :available,
      :platform,
      :truck_number,
      :customer_id
    ]

    model
    |> cast(params, required_fields ++ optional_fields)
    |> validate_required(required_fields)
  end
end
