defmodule Slax.Round do
  @moduledoc false

  use Slax.Schema

  @type t :: %__MODULE__{}
  schema "rounds" do
    field(:channel, :string)
    field(:closed, :boolean)
    field(:issue, :string)
    field(:response_url, :string)
    field(:revealed, :boolean)
    field(:value, :integer)

    timestamps()
  end
end
