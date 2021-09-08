defmodule SlaxWeb.Plugs.LoadUser do
  @moduledoc """
  Loads a user into the assigns, if they have a session
  """

  use SlaxWeb, :plug
  alias Slax.Users

  def init(opts) do
    opts
  end

  def call(conn, _) do
    handle_auth(conn)
  end

  defp handle_auth(conn) do
    user_id = get_session(conn, :user_id)

    if is_nil(user_id) do
      conn
    else
      current_user = Users.get_user(id: user_id)
      assign(conn, :current_user, current_user)
    end
  end
end
