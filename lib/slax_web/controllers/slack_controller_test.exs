defmodule SlaxWeb.SlackControllerTest do
  use SlaxWeb.ConnCase

  describe "message" do
    test "url verification", %{conn: conn} do
      body = %{type: "url_verification", challenge: "test"}
      conn = post(conn, Routes.slack_path(conn, :message), body)
      assert response(conn, 200) == "test"
    end
  end
end
