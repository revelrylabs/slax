defmodule SlaxWeb.AuthController do
  use SlaxWeb, :controller

  alias Slax.{Users, Github}

  plug(Slax.Plugs.VerifySlackToken, token: :auth)

  def start(conn, %{"user_id" => user_id, "text" => text}) do
    case text do
      "" ->
        text(conn, "*AuthBot services:*\n\n/auth github")

      "github" ->
        github_redirect(conn, %{user_id: user_id})

      _ ->
        text(conn, "Unknown provider")
    end
  end

  def github_redirect(conn, %{user_id: state}) do
    client_id =
      Application.get_env(:slax, Slax.Github)
      |> Keyword.get(:client_id)

    authorization_url =
      Github.authorize_url(%{
        client_id: client_id,
        scope: "repo",
        state: state
      })

    text(conn, authorization_url)
  end

  def github_callback(conn, %{"state" => state, "code" => code}) do
    github_creds = Application.get_env(:slax, Slax.Github)

    IO.inspect(github_creds)

    access_token =
      Github.fetch_access_token(%{
        client_id: github_creds[:client_id],
        client_secret: github_creds[:client_secret],
        code: code,
        state: state
      })

    IO.inspect(access_token)

    %{"login" => github_username} =
      Github.current_user_info(%{
        access_token: access_token
      })

    params = %{
      github_username: github_username,
      github_access_token: access_token
    }

    Users.create_or_update_user(state, params)

    text(conn, "Authentication successful! You can close this window.")
  end
end
