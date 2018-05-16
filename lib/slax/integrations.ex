defmodule Slax.Integrations do
  @moduledoc """
  Indirection to Integration modules.
  Mainly so we can replace them during testing
  """

  def github() do
    Application.get_env(:slax, :integrations)[:github]
  end

  def slack() do
    Application.get_env(:slax, :integrations)[:slack]
  end
end
