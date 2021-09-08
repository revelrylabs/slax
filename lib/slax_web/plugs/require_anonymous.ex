defmodule SlaxWeb.Plugs.RequireAnonymous do
  @moduledoc """
  Redirects a user to the account page if they are logged in
  """

  use SlaxWeb, :plug

  def init(opts) do
    opts
  end

  def call(%{assigns: %{current_user: %{id: _id}}} = conn, _opts) do
    conn
    |> redirect(to: Routes.live_path(conn, SlaxWeb.LiveViews.Account))
    |> halt()
  end

  def call(conn, _opts), do: conn
end
