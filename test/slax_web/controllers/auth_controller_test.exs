defmodule SlaxWeb.AuthController.Test do
  use SlaxWeb.ConnCase, async: true

  setup %{conn: conn} do
    bypass = Bypass.open()
    url = "http://localhost:#{bypass.port}"

    Application.put_env(
      :slax,
      Slax.Github,
      api_url: url,
      oauth_url: url
    )

    {:ok, conn: conn, bypass: bypass, url: url}
  end

  test "sends usage message when there is no text", %{conn: conn} do
    params = %{
      user_id: "1",
      token: "token",
      text: "",
      channel_id: "blah",
      timestamp: "12345"
    }

    conn = post(conn, auth_path(conn, :start), params)
    assert response(conn, 200) =~ "AuthBot services"
  end

  test "sends unknown provider message", %{conn: conn} do
    params = %{
      user_id: "1",
      token: "token",
      text: "unknown",
      channel_id: "blah",
      timestamp: "12345"
    }

    conn = post(conn, auth_path(conn, :start), params)
    assert response(conn, 200) =~ "Unknown provider"
  end

  test "send github auth url", %{conn: conn} do
    params = %{
      user_id: "1",
      token: "token",
      text: "github",
      channel_id: "blah",
      timestamp: "12345"
    }

    conn = post(conn, auth_path(conn, :start), params)
    assert response(conn, 200) =~ "http"
  end

  test "github_redirect", %{conn: conn, url: url} do
    conn = get(conn, auth_path(conn, :github_redirect), state: "state")
    assert redirected_to(conn) =~ url
  end

  test "github_callback", %{conn: conn, bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/access_token", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"access_token": "12345"}>)
    end)

    Bypass.expect_once(bypass, "GET", "/user", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"login": "test"}>)
    end)

    conn = get(conn, auth_path(conn, :github_callback), state: "state", code: "code")
    assert response(conn, 200) =~ "Authentication successful!"
  end
end
