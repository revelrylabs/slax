defmodule SlaxWeb.AuthController.Test do
  use SlaxWeb.ConnCase, async: true
  import Mox

  setup :verify_on_exit!

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

  test "github_redirect", %{conn: conn} do
    Slax.GithubMock
    |> expect(:authorize_url, fn _ -> "https://github.com" end)

    conn = get(conn, auth_path(conn, :github_redirect), state: "state")
    assert redirected_to(conn) =~ "https://github.com"
  end

  @tag :skip
  # Re-enable once we figure out db
  test "github_callback", %{conn: conn} do
    Slax.GithubMock
    |> expect(:fetch_access_token, fn _ -> "12345" end)
    |> expect(:current_user_info, fn _ -> %{"login" => "test"} end)

    conn = get(conn, auth_path(conn, :github_callback), state: "state", code: "code")
    assert response(conn, 200) =~ "Authentication successful!"
  end
end
