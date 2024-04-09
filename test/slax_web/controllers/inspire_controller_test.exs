defmodule SlaxWeb.InspireController.Test do
  use SlaxWeb.ConnCase, async: true
  import Mox

  setup :verify_on_exit!

  test "halts when token doesn't match", %{conn: conn} do
    expect(Slax.HttpMock, :post, fn _, _, _, _ ->
      {:ok, %HTTPoison.Response{status_code: 200, body: ~s<{""}>}}
    end)

    params = %{
      text: "inspire",
      channel_name: "blah"
    }

    conn =
      conn
      |> put_req_header("x-slack-signature", "invalid token")
      |> put_req_header("x-slack-request-timestamp", "12345")
      |> post(inspire_path(conn, :start), params)

    assert response(conn, 200) == ""
  end
end
