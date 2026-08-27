defmodule Slax.PokerTest do
  use Slax.ModelCase

  alias Slax.Poker

  @slack_max_frame_bytes 20_480

  describe "truncate_body/1" do
    test "returns an empty string for a missing body" do
      assert Poker.truncate_body(nil) == ""
    end

    test "leaves short bodies untouched" do
      assert Poker.truncate_body("short body") == "short body"
    end

    test "truncates long bodies and appends a notice" do
      result = Poker.truncate_body(String.duplicate("x", 25_000))

      assert String.length(result) < 3_100
      assert String.ends_with?(result, "_[body truncated, see the issue link]_")
    end
  end

  describe "start_round/2" do
    test "keeps the response inside Slack's socket-mode frame limit" do
      issue = %{
        "url" => "https://api.github.com/repos/org/repo/issues/1",
        "html_url" => "https://github.com/org/repo/issues/1",
        "number" => 1,
        "title" => "Huge issue",
        "labels" => [],
        "comments" => 0,
        "body" => String.duplicate("line of spec text\n", 1_500)
      }

      {:ok, response} = Poker.start_round("tech-poker", issue)

      frame =
        Jason.encode!(%{
          envelope_id: "abc",
          payload: %{response_type: "in_channel", text: response}
        })

      assert byte_size(frame) < @slack_max_frame_bytes
      assert response =~ "Planning poker for org/repo/1"
      assert response =~ "_[body truncated, see the issue link]_"
    end
  end
end
