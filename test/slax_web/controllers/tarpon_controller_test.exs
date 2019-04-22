defmodule SlaxWeb.TarponController.Test do
  use SlaxWeb.ConnCase, async: true
  import Mox

  setup :verify_on_exit!

  test "halts when token doesn't match", %{conn: conn} do
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

  test "does not send a reaction when text is not tarpon", %{conn: conn} do
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

  test "sends a reaction when text is not tarpon", %{conn: conn} do
    Slax.HttpMock
    |> expect(:post, fn _, _, _, _ ->
      {:ok, %HTTPoison.Response{status_code: 200, body: ~s<{"ok": true}>}}
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
