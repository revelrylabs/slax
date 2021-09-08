defmodule SlaxWeb.Plugs.RequireAuthenticated do
  @moduledoc """
  Restricts anonymous users from accessing certain routes
  """

  use SlaxWeb, :plug

  @error_msg "Please sign in to view that page."

  def init(opts) do
    opts
  end

  def call(%{assigns: %{current_user: %{id: _id}}} = conn, _opts) do
    conn
  end

  def call(conn, _opts) do
    conn
    |> put_flash(:error, @error_msg)
    |> redirect(to: Routes.live_path(conn, SlaxWeb.LiveViews.Home))
    |> halt()
  end
end
