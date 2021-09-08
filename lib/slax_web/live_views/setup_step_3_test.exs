defmodule SlaxWeb.LiveViews.SetupStep3Test do
  use SlaxWeb.ConnCase

  alias Slax.Users

  describe "setup step 3" do
    test "finish is not shown until both privacy and terms are checked", %{conn: conn} do
      {:ok, view, html} = live(conn, Routes.live_path(conn, SlaxWeb.LiveViews.SetupStep3))

      refute html =~ "Finish"

      view
      |> element("form")
      |> render_change(%{privacy: "on", terms: "on"})

      assert render(view) =~ "Finish"
    end

    test "back button redirects to step 2", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, SlaxWeb.LiveViews.SetupStep3))

      view
      |> element("a[href=\"#{Routes.live_path(conn, SlaxWeb.LiveViews.SetupStep2)}\"]")
      |> render_click()

      assert_redirect(view, Routes.live_path(conn, SlaxWeb.LiveViews.SetupStep2))
    end

    test "finish button works", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, SlaxWeb.LiveViews.SetupStep3))

      view
      |> element("form")
      |> render_change(%{privacy: "on", terms: "on"})

      view
      |> element("[phx-click=finish]")
      |> render_click()

      assert %DateTime{} =
               Users.get_user(id: conn.assigns.current_user.id)
               |> Map.get(:teams)
               |> List.first()
               |> Map.get(:onboarded_at)

      assert_redirect(view, Routes.live_path(conn, SlaxWeb.LiveViews.SetupSuccess))
    end
  end
end
