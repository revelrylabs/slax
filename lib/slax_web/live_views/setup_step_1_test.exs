defmodule SlaxWeb.LiveViews.SetupStep1Test do
  use SlaxWeb.ConnCase

  describe "setup step 1" do
    test "Next button redirects to step 2", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, SlaxWeb.LiveViews.SetupStep1))

      view
      |> element("a[href=\"#{Routes.live_path(conn, SlaxWeb.LiveViews.SetupStep2)}\"]")
      |> render_click()

      assert_redirect(view, Routes.live_path(conn, SlaxWeb.LiveViews.SetupStep2))
    end
  end
end
