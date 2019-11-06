defmodule SlaxWeb.InspireController.Test do
  use SlaxWeb.ConnCase, async: true
  import Mox

  setup :verify_on_exit!

  test "halts when token doesn't match", %{conn: conn} do
    params = %{
      token: "non_matching_token",
      text: "test",
      channel_name: "blah",
      timestamp: "12345"
    }

    conn =
      conn
      |> post(inspire_path(conn, :start), params)

    assert response(conn, 200) == "Invalid slack token."
  end

  test "does not send a message when text is not inspire", %{conn: conn} do
    params = %{
      token: "token",
      text: "test",
      channel_name: "blah",
      timestamp: "12345"
    }

    conn =
      conn
      |> post(inspire_path(conn, :start), params)

    assert response(conn, 200) == ""
  end

  test "sends a message when text is inspire", %{conn: conn} do
    Slax.HttpMock
    |> expect(:post, fn _, _, _, _ ->
      {:ok, %HTTPoison.Response{status_code: 200, body: ~s<{"ok": true}>}}
    end)

    params = %{
      token: "token",
      text: "tarpon",
      channel_name: "blah",
      timestamp: "12345"
    }

    conn =
      conn
      |> post(inspire_path(conn, :start), params)

    assert response(conn, 200) == ""
  end
end
