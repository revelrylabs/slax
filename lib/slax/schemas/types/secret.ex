defmodule Slax.Schemas.Types.Secret do
  @moduledoc """
  Provides an ecto type for secrets.
  """
  use Cloak.Ecto.Binary, vault: Slax.Vault
end
