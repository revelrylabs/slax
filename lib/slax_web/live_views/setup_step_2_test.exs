defmodule SlaxWeb.LiveViews.SetupStep2Test do
  use SlaxWeb.ConnCase
  import Mox

  describe "setup step 2" do
    test "when a user click next without selecting anything", %{conn: conn} do
      expect(Slax.Slack.RequestMock, :get, fn "conversations.list", _, _ ->
        {:ok, %{"ok" => true, "channels" => []}, 200}
      end)

      {:ok, view, _html} = live(conn, Routes.live_path(conn, SlaxWeb.LiveViews.SetupStep2))

      view
      |> element("[phx-click=next]")
      |> render_click()

      assert_redirect(view, Routes.live_path(conn, SlaxWeb.LiveViews.SetupStep3))
    end

    test "when a user selects a channel and selects yes", %{conn: conn} do
      expect(Slax.Slack.RequestMock, :get, fn "conversations.list", _, _ ->
        {:ok, %{"ok" => true, "channels" => []}, 200}
      end)

      {:ok, view, _html} = live(conn, Routes.live_path(conn, SlaxWeb.LiveViews.SetupStep2))

      view
      |> element("form")
      |> render_change(%{channel_id: "1", send: "yes"})

      view
      |> element("[phx-click=next]")
      |> render_click()

      assert_redirect(view, Routes.live_path(conn, SlaxWeb.LiveViews.SetupStep3))

      team =
        Slax.Users.get_user(id: conn.assigns.current_user.id) |> Map.get(:teams) |> List.first()

      assert Map.get(team, :welcome_channel_slack_id) == "1"
      assert Map.get(team, :send_welcome_message)
    end
  end
end
