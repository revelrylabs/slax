defmodule Slax.Slack.Test do
  use Slax.ModelCase, async: true
  alias Slax.Slack

  import Mox

  setup :verify_on_exit!

  test "send_message/1" do
    expect(Slax.HttpMock, :post, fn _, _, _, _ ->
      {:ok, %HTTPoison.Response{status_code: 200, body: ~s<{"ok": true}>}}
    end)

    assert {:ok,
            %{
              status_code: 200,
              body: %{"ok" => true}
            }} = Slack.send_message("", "Hello")
  end

  def create_channel_setup(context) do
    url = "/channels.create"

    {:ok, context |> Map.put(:url, url)}
  end

  describe "create_channel/1" do
    setup [:create_channel_setup]

    test "success" do
      expect(Slax.HttpMock, :post, fn _, _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 201, body: ~s<{"ok": true, "channel": "test"}>}}
      end)

      assert Slack.create_channel("test") == {:ok, "test"}
    end

    test "failure" do
      expect(Slax.HttpMock, :post, fn _, _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 400,
           body: ~s<{"ok": false, "error": "Something happened"}>
         }}
      end)

      assert Slack.create_channel("test") == {:error, "Something happened"}
    end
  end

  def add_reaction_setup(context) do
    url = "/reactions.add"

    {:ok, context |> Map.put(:url, url)}
  end

  describe "add_reaction/1" do
    setup [:add_reaction_setup]

    test "success" do
      expect(Slax.HttpMock, :post, fn _, _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 200, body: ~s<{"ok": true}>}}
      end)

      assert {:ok,
              %{
                status_code: 200,
                body: %{"ok" => true}
              }} =
               Slack.add_reaction(%{
                 name: "smile",
                 channel_id: "12345",
                 timestamp: "12345"
               })
    end
  end

  def post_message_to_channel_setup(context) do
    url = "/chat.postMessage"

    {:ok, context |> Map.put(:url, url)}
  end

  describe "post_message_to_channel/1" do
    setup [:post_message_to_channel_setup]

    test "success" do
      expect(Slax.HttpMock, :post, fn _, _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 200, body: ~s<{"ok": true}>}}
      end)

      assert :ok ==
               Slack.post_message_to_channel("test message", "#channel")
    end
  end

  def post_message_to_thread_setup(context) do
    url = "/chat.postMessage"

    {:ok, context |> Map.put(:url, url)}
  end

  describe "post_message_to_thread/1" do
    setup [:post_message_to_channel_setup]

    test "success" do
      expect(Slax.HttpMock, :post, fn _, _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 200, body: ~s<{"ok": true}>}}
      end)

      assert :ok ==
               Slack.post_message_to_thread(%{
                 text: "test message",
                 channel: "#channel",
                 thread_ts: "thread_ts"
               })
    end
  end

  def open_modal_setup(context) do
    url = "/views.open"

    {:ok, context |> Map.put(:url, url)}
  end

  describe "open_modal/1" do
    setup [:open_modal_setup]

    test "success" do
      expect(Slax.HttpMock, :post, fn _, _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 200, body: ~s<{"ok": true}>}}
      end)

      assert :ok == Slack.open_modal(%{trigger_id: "trigger_id", view: %{}})
    end
  end

  def update_modal_setup(context) do
    url = "/views.update"
    {:ok, context |> Map.put(:url, url)}
  end

  describe "update_modal/1" do
    setup [:update_modal_setup]

    test "success" do
      expect(Slax.HttpMock, :post, fn _, _, _, _ ->
        {:ok, %HTTPoison.Response{status_code: 200, body: ~s<{"ok": true}>}}
      end)

      assert :ok == Slack.update_modal(%{trigger_id: "trigger_id", view: %{}, view_id: "view_id"})
    end
  end

  describe "chunk_message/1" do
    test "returns short text as a single message" do
      assert Slack.chunk_message("hello\nworld") == ["hello\nworld"]
    end

    test "splits on line breaks, keeps every message within the limit, loses nothing" do
      text = String.duplicate("line of spec text\n", 1_500)
      chunks = Slack.chunk_message(text)

      assert length(chunks) > 1
      assert Enum.all?(chunks, &(String.length(&1) <= 4_000))
      assert Enum.join(chunks, "\n") == text
    end

    test "hard-splits a single line longer than the limit" do
      chunks = Slack.chunk_message(String.duplicate("x", 9_000))

      assert Enum.map(chunks, &String.length/1) == [4_000, 4_000, 1_000]
    end
  end

  describe "post_long_message_to_channel/2" do
    test "posts every chunk to the channel in order" do
      text = String.duplicate("line of spec text\n", 1_500)
      expected = Slack.chunk_message(text)
      {:ok, posted} = Agent.start_link(fn -> [] end)

      expect(Slax.HttpMock, :post, length(expected), fn _, body, _, _ ->
        Agent.update(posted, &[URI.decode_query(body) | &1])
        {:ok, %HTTPoison.Response{status_code: 200, body: ~s<{"ok": true}>}}
      end)

      Slack.post_long_message_to_channel(text, "tech-poker")

      requests = posted |> Agent.get(& &1) |> Enum.reverse()
      assert Enum.map(requests, & &1["text"]) == expected
      assert Enum.all?(requests, &(&1["channel"] == "tech-poker"))
    end
  end
end
