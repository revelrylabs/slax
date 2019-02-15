defmodule Slax.Commander do
  @moduledoc """
  Handles the execution of commands
  """

  @spec run(Slax.User.t(), binary()) :: binary()
  def run(user, command)

  def run(_user, "ping") do
    "pong"
  end

  def run(user, command) do
    """
    *Slax commands:*
    """
  end
end
