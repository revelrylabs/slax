defmodule Slax.Plugs.VerifyUser do
  @moduledoc false
  import Phoenix.Controller, only: [text: 2]
  import Plug.Conn, only: [assign: 3, halt: 1]

  # Required for a plug
  def init(_) do
  end

  def call(%Plug.Conn{params: %{"user_id" => user_id}} = conn, _) do
    case Slax.Users.get_user(user_id) do
      nil -> conn |> text("You need to authenticate! use `/auth github`") |> halt
      user -> assign(conn, :current_user, user)
    end
  end
end
