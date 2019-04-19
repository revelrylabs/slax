defmodule SlaxWeb.BlockerController.Test do
  use SlaxWeb.ConnCase, async: true

  setup %{conn: conn} do    
    bypass = Bypass.open()
    url = "http://localhost:#{bypass.port}"

    Application.put_env(
      :slax,
      Slax.Slack,
      api_url: url,
      api_token: "token",
      tokens: [
        comment: "token",
        issue: "token",
        auth: "token",
        tarpon: "token",
        project: "token",
        sprint: "token",
        slax: "token",
        blocker: "token"
      ]
    )

    Application.put_env(
      :slax,
      Slax.Github,
      api_url: url,
      oauth_url: url,
      org_name: "organization"
    )

    {:ok, conn: conn, bypass: bypass, url: url}
  end

  test "halts on invalid token", %{conn: conn, bypass: bypass} do
    Bypass.stub(bypass, "POST", "/chat.postMessage", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"ok": true}>)
    end)

    params = %{
      token: "invalid token",
      text: "get-in-progress-issues",
      channel_id: "CV2345DJ",
      timestamp: "2018-12-03 16:16:59"
    }

    conn =
      conn
      |> post(blocker_path(conn, :start), params)

    assert response(conn, 200) == "Invalid slack token."
  end

  describe "use authenticated user" do
    test "returns a response when requesting all in progress issues", %{conn: conn, bypass: bypass} do
      insert(:user)

      Bypass.stub(bypass, "POST", "/chat.postMessage", fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{"ok": true}>)
      end)

      params = %{
        user_id: "slack",
        token: "token",
        text: "get-in-progress-issues",
        channel_name: "test",
        response_url: "slack.my.com/234234"
      }

      conn =
        conn
        |> post(blocker_path(conn, :start), params)

      assert response(conn, 201) == ""
    end
  end
end
