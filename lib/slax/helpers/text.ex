defmodule Slax.Helpers.Text do
  @doc """
  Takes in a list and joins the elements by comma and the word and

  ## Examples

      iex> to_sentence([])
      ""
      iex> to_sentence(["hi"])
      "hi"
      iex> to_sentence(["hi", "hello"])
      "hi and hello"
      iex> to_sentence(["hi", "hello", "sup"])
      "hi, hello, and sup"

  """
  def to_sentence([]), do: ""
  def to_sentence([single]), do: single
  def to_sentence([one, two]), do: "#{one} and #{two}"
  def to_sentence(list) do
    {last, rest} = List.pop_at(list, -1)
    "#{Enum.join(rest, ", ")}, and #{last}"
  end
end
