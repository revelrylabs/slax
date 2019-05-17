defmodule SlaxWeb.BlockerController.Test do
  use SlaxWeb.ConnCase, async: true
  import Mox

  setup :verify_on_exit!

  test "halts on invalid token", %{conn: conn} do
    params = %{
      token: "invalid token",
      text: "get-in-progress-issues",
      channel_id: "CV2345DJ",
      timestamp: "2018-12-03 16:16:59"
    }

    conn =
      conn
      |> post(blocker_path(conn, :start), params)

    assert response(conn, 200) == "Invalid slack token."
  end

  describe "use authenticated user" do
    test "returns a response when requesting all in progress issues", %{
      conn: conn
    } do
      insert(:user)

      params = %{
        user_id: "slack",
        token: "token",
        text: "get-in-progress-issues",
        channel_name: "test",
        response_url: "slack.my.com/234234"
      }

      conn =
        conn
        |> post(blocker_path(conn, :start), params)

      assert response(conn, 200) =~ "Get issues"
    end
  end
end
