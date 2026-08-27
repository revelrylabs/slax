defmodule Slax.PokerTest do
  use Slax.ModelCase

  alias Slax.Poker

  describe "start_round/2" do
    test "keeps the full issue body in the response" do
      body = String.duplicate("line of spec text\n", 1_500)

      issue = %{
        "url" => "https://api.github.com/repos/org/repo/issues/1",
        "html_url" => "https://github.com/org/repo/issues/1",
        "number" => 1,
        "title" => "Huge issue",
        "labels" => [],
        "comments" => 0,
        "body" => body
      }

      {:ok, response} = Poker.start_round("tech-poker", issue)

      assert response =~ "Planning poker for org/repo/1"
      assert String.contains?(response, body)
    end
  end
end
