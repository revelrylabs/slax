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

  test "github_callback", %{conn: conn} do
    Slax.HttpMock
    |> expect(:post, fn _, _, _, _ ->
      {:ok, %HTTPoison.Response{status_code: 200, body: ~s<{"access_token": "12345"}>}}
    end)
    |> expect(:get, fn _, _, _ ->
      {:ok, %HTTPoison.Response{status_code: 200, body: ~s<{"login": "test"}>}}
    end)

    conn = get(conn, auth_path(conn, :github_callback), state: "state", code: "code")
    assert response(conn, 200) =~ "Authentication successful!"
  end
end
