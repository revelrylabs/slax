defmodule Slax.Commander.Test do
  use Slax.ModelCase, async: true
  alias Slax.Commander
  use ExUnitProperties

  test "ping" do
    assert Commander.run(%{}, ["ping"]) == "pong"
  end

  test "help" do
    assert Commander.run(%{}, []) =~ "commands"
  end

  test "roll with a 0" do
    assert Commander.run(%{}, ["roll", "0"]) =~ "commands"
  end

  test "roll with a negative number" do
    assert Commander.run(%{}, ["roll", "-1"]) =~ "commands"
  end

  test "roll with an invalid number" do
    assert Commander.run(%{}, ["roll", "tacos"]) =~ "commands"
  end

  property "roll will always be between 1 and n" do
    check all(sides <- integer(1..1000)) do
      result = Commander.run(%{}, ["roll", to_string(sides)])
      [_, num] = String.split(result, ": ")
      {result, _} = Integer.parse(num)

      assert result >= 1
      assert result <= sides
    end
  end
end
