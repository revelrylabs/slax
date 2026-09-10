defmodule Slax.Poker.Test do
  use Slax.ModelCase, async: true

  alias Slax.Poker
  alias Slax.Poker.Round

  @issue %{
    "url" => "https://api.github.com/repos/revelrylabs/slax/issues/42",
    "html_url" => "https://github.com/revelrylabs/slax/issues/42",
    "number" => 42,
    "title" => "Render <markdown> & stuff",
    "labels" => [%{"name" => "bug"}, %{"name" => "poker"}],
    "comments" => 1,
    "body" => "## Summary\r\n\r\nSome **bold** text.\r\n\r\n- [ ] a task\r\n- an item"
  }

  describe "start_round/2" do
    test "opens a round for the channel" do
      {:ok, _response} = Poker.start_round("general", @issue)

      assert %Round{issue: "revelrylabs/slax/42", closed: false} =
               Repo.get_by(Round, channel: "general")
    end

    test "renders the issue as Slack mrkdwn" do
      {:ok, response} = Poker.start_round("general", @issue)

      assert response =~ "*Planning poker for revelrylabs/slax/42*\n"
      assert response =~ "*42: Render &lt;markdown&gt; &amp; stuff* (bug, poker)\n"
      assert response =~ "---\n*Summary*\n\nSome *bold* text.\n\n☐ a task\n• an item\n---\n"
      assert response =~ "https://github.com/revelrylabs/slax/issues/42\n"
      assert response =~ "This issue has 1 comment\n"
      assert response =~ "\n_Reminder: all of the work counts"
      refute response =~ "**"
    end

    test "marks pull requests and handles a missing body and labels" do
      issue =
        @issue
        |> Map.merge(%{"body" => nil, "labels" => [], "comments" => 3})
        |> Map.put("pull_request", %{})

      {:ok, response} = Poker.start_round("general", issue)

      assert response =~ "*(PR) 42: Render &lt;markdown&gt; &amp; stuff*\n"
      assert response =~ "---\n_No description._\n---\n"
      assert response =~ "This issue has 3 comments\n"
    end

    test "keeps the full issue body in the response" do
      body = String.duplicate("line of spec text\n", 1_500)

      {:ok, response} = Poker.start_round("tech-poker", Map.put(@issue, "body", body))

      assert response =~ "Planning poker for revelrylabs/slax/42"
      assert String.contains?(response, body)
    end
  end
end
