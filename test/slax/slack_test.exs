defmodule Slax.Slack.Test do
  use Slax.ModelCase, async: true
  alias Slax.Slack

  setup do
    bypass = Bypass.open()
    url = "http://localhost:#{bypass.port}"

    Application.put_env(
      :slax,
      Slax.Slack,
      api_url: url,
      api_token: "token"
    )

    {:ok, bypass: bypass, url: url}
  end

  test "send_message/1", %{bypass: bypass, url: url} do
    Bypass.expect_once(bypass, "POST", "/", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"ok": true}>)
    end)

    assert %HTTPotion.Response{
             status_code: 200,
             body: "{\"ok\": true}"
           } =
             Slack.send_message(url, %{
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

    test "success", %{bypass: bypass, url: url} do
      Bypass.expect_once(bypass, "POST", url, fn conn ->
        Plug.Conn.resp(conn, 201, ~s<{"ok": true, "channel": "test"}>)
      end)

      assert Slack.create_channel("test") == {:ok, "test"}
    end

    test "failure", %{bypass: bypass, url: url} do
      Bypass.expect_once(bypass, "POST", url, fn conn ->
        Plug.Conn.resp(conn, 400, ~s<{"ok": false, "error": "Something happened"}>)
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

    test "success", %{bypass: bypass, url: url} do
      Bypass.expect_once(bypass, "POST", url, fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{"ok": true}>)
      end)

      assert %HTTPotion.Response{
               status_code: 200,
               body: "{\"ok\": true}"
             } =
               Slack.add_reaction(%{
                 name: "smile",
                 channel_id: "12345",
                 timestamp: "12345"
               })
    end
  end
end
