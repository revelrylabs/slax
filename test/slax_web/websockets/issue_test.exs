defmodule SlaxWeb.Issue.Test do
  use SlaxWeb.ConnCase, async: true
  import Mox

  alias SlaxWeb.Issue

  setup :verify_on_exit!

  test "ignores non relevant events", _ do
    event1 = %{"subtype" => "bot_message"}
    event2 = %{"subtype" => "message_changed"}
    event3 = %{"type" => "not_a_message"}
    event4 = %{"bot_id" => "beep123"}

    assert Issue.handle_event(event1) == nil
    assert Issue.handle_event(event2) == nil
    assert Issue.handle_event(event3) == nil
    assert Issue.handle_event(event4) == nil
  end

  test "ignores disabled channel", _ do
    channel = insert(:channel, disabled: true)
    event1 = %{"channel" => channel.channel_id, "text" => "test#123", "type" => "message"}
    event2 = %{"channel" => channel.channel_id, "text" => "test$123", "type" => "message"}

    assert Issue.handle_event(event1) == nil
    assert Issue.handle_event(event2) == nil
  end

  test "test regex to match issue pattern", _ do
    strings_with_matching_pattern = [
      {"some extra text slax-test#1 some extra text", [["slax-test#1", "", "slax-test", "#1"]]},
      {"slax-test#1 some extra text test#2",
       [["slax-test#1", "", "slax-test", "#1"], ["test#2", "", "test", "#2"]]},
      {"extra org/repo#1 extra", [["org/repo#1", "org/", "repo", "#1"]]}
    ]

    Enum.each(strings_with_matching_pattern, fn {string, result} ->
      assert result == Issue.scan_text_for_issue(string)
    end)

    strings_with_no_matching_pattern = [
      "test#number",
      "test #number",
      "test # number",
      "#number",
      "#1",
      "test #1",
      "/1",
      "test/1"
    ]

    Enum.each(strings_with_no_matching_pattern, fn string ->
      assert [] == Issue.scan_text_for_issue(string)
    end)
  end
end
