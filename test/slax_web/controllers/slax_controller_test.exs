defmodule SlaxWeb.SlaxController.Test do
  use SlaxWeb.ConnCase, async: true
  import Mox

  setup :verify_on_exit!

  setup %{conn: conn} do
    [conn: conn]
  end

  test "responds to ping", %{conn: conn} do
    params = %{
      token: "token",
      text: "ping",
      channel_id: "blah",
      timestamp: "12345",
      response_url: "https://google.com"
    }

    conn =
      conn
      |> post(slax_path(conn, :start), params)

    assert response(conn, 201) == ""
  end
end
