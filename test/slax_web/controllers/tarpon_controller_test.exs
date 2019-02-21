defmodule SlaxWeb.TarponController.Test do
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
        slax: "token"
      ]
    )

    {:ok, conn: conn, bypass: bypass, url: url}
  end

  test "halts when token doesn't match", %{conn: conn, bypass: bypass} do
    Bypass.stub(bypass, "POST", "/reactions.add", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"ok": true}>)
    end)

    params = %{
      token: "non_matching_token",
      text: "test",
      channel_id: "blah",
      timestamp: "12345"
    }

    conn =
      conn
      |> post(tarpon_path(conn, :start), params)

    assert response(conn, 200) == "Invalid slack token."
  end

  test "does not send a reaction when text is not tarpon", %{conn: conn, bypass: bypass} do
    Bypass.stub(bypass, "POST", "/reactions.add", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"ok": true}>)
    end)

    params = %{
      token: "token",
      text: "test",
      channel_id: "blah",
      timestamp: "12345"
    }

    conn =
      conn
      |> post(tarpon_path(conn, :start), params)

    assert response(conn, 200) == ""
  end

  test "sends a reaction when text is not tarpon", %{conn: conn, bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/reactions.add", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"ok": true}>)
    end)

    params = %{
      token: "token",
      text: "tarpon",
      channel_id: "blah",
      timestamp: "12345"
    }

    conn =
      conn
      |> post(tarpon_path(conn, :start), params)

    assert response(conn, 200) == ""
  end
end
