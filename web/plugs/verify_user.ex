defmodule Slax.Plugs.VerifyUser do
  import Phoenix.Controller
  import Plug.Conn, only: [assign: 3]

  # Required for a plug
  def init(_) do
  end

  def call(%Plug.Conn{params: %{"user_id" => user_id}} = conn, _) do
    case Slax.Repo.get_by(Slax.User, slack_id: user_id) do
      nil -> text conn, "You need to authenticate! use `/auth github`"
      user -> assign(conn, :current_user, user)
    end
  end
end
