defmodule Slax.Account do
  @moduledoc """
  This module provides a simple account management system.
  """
  alias Slax.Account.Authenticate

  @spec authenticate(any) ::
          {:ok, map()}
          | {:error, any()}
          | {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}
  defdelegate authenticate(attrs), to: Authenticate
end
