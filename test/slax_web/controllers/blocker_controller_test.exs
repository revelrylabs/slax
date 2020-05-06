defmodule SlaxWeb.BlockerController.Test do
  use SlaxWeb.ConnCase, async: true
  import Mox

  setup :verify_on_exit!

  test "halts on invalid token", %{conn: conn} do
    params = %{
      response_url: "blah",
      channel_name: "test",
      text: "latency",
      user_id: "0"
    }

    conn =
      conn
      |> put_req_header("x-slack-signature", "invalid token")
      |> put_req_header("x-slack-request-timestamp", "12345")
      |> post(blocker_path(conn, :start), params)

    assert response(conn, 200) == "You need to authenticate! use `/auth github`"
  end
end
