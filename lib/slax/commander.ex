defmodule Slax.Commander do
  @moduledoc """
  Handles the execution of commands
  """

  @spec run(Slax.Commands.Context.t(), [String.t()]) :: binary()
  def run(context, command)

  def run(_context, ["ping"]) do
    "pong"
  end

  def run(_context, _command) do
    """
    *Slax commands:*

    Usage: /slax [command] [options]

    Commands:

    ping    Checks to make sure the server is alive
    """
  end
end
