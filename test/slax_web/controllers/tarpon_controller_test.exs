defmodule SlaxWeb.TarponController.Test do
  use SlaxWeb.ConnCase, async: true
  import Mox

  setup :verify_on_exit!

  test "halts when token doesn't match", %{conn: conn} do
    params = %{
      command: "tarpon",
      response_url: "blah"
    }

    conn =
      conn
      |> put_req_header("x-slack-signature", "invalid token")
      |> put_req_header("x-slack-request-timestamp", "12345")
      |> post(tarpon_path(conn, :start), params)

    assert response(conn, 200) == ""
  end
end
