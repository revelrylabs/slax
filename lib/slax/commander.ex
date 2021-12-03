defmodule Slax.Commander do
  @moduledoc """
  Handles the execution of commands
  """

  @spec run(Slax.Commands.Context.t(), [String.t()]) :: binary()
  def run(context, command)

  def run(_context, ["ping"]) do
    "pong"
  end

  def run(context, ["roll", number]) do
    case Integer.parse(number) do
      :error ->
        run(context, ["help"])

      {num, _} when num <= 0 ->
        run(context, ["help"])

      {num, _} ->
        num = :rand.uniform(num)

        "#{number}-sided die rolled. You rolled: #{num}"
    end
  end

  def run(_context, _command) do
    """
    *Slax commands:*

    Usage: /slax [command] [options]

    Commands:

    ping    Checks to make sure the server is alive
    roll [number-of-sides]  Rolls an n-sided die and returns the result
    """
  end
end
