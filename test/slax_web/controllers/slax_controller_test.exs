defmodule SlaxWeb.SlaxController.Test do
  use SlaxWeb.ConnCase, async: true
  import Mox

  setup :verify_on_exit!

  setup %{conn: conn} do
    user = insert(:user)

    conn = assign(conn, :user_id, user.id)

    [conn: conn, user: user]
  end

  test "responds to ping", %{conn: conn, user: user} do
    params = %{
      token: "token",
      text: "ping",
      channel_id: "blah",
      timestamp: "12345",
      response_url: "https://google.com",
      user_id: user.slack_id
    }

    conn =
      conn
      |> post(slax_path(conn, :start), params)

    assert response(conn, 201) == ""
  end
end
