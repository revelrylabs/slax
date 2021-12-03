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
            }} =
             Slack.send_message("", %{
               response_type: "in_channel",
               text: "Hello"
             })
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
               Slack.post_message_to_channel(%{
                 text: "test message",
                 channel_name: "#channel"
               })
    end
  end
end
