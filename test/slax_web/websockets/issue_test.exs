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

  test "test regex", _ do
    assert [["slax-test#1", "", "slax-test", "#1"]] ==
             Issue.scan_text("some extra text slax-test#1 some extra text")

    assert [["slax-test#1", "", "slax-test", "#1"], ["test#2", "", "test", "#2"]] ==
             Issue.scan_text("slax-test#1 some extra text test#2")

    assert [["org/repo#1", "org/", "repo", "#1"]] == Issue.scan_text("garbage org/repo#1 garb")

    assert [] == Issue.scan_text("test#number")
    assert [] == Issue.scan_text("test #number")
    assert [] == Issue.scan_text("test # number")
    assert [] == Issue.scan_text("#number")
    assert [] == Issue.scan_text("#1")
    assert [] == Issue.scan_text("test #1")
    assert [] == Issue.scan_text("/1")
    assert [] == Issue.scan_text("test/1")
  end
end
