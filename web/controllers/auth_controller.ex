defmodule Slax.AuthController do
  use Slax.Web, :controller

  alias Slax.{Repo, User}

  def start(conn, %{"user_id" => user_id, "text" => text}) do
    case text do
      "github" ->
        text conn, auth_url(conn, :github_redirect, %{state: user_id})
      _ ->
        text conn, "Unknown provider"
    end
  end

  def github_redirect(conn, %{"state" => state}) do
    client_id = Application.get_env(:slax, :github)
    |> Keyword.get(:client_id)

    authorization_url = Github.authorize_url(%{
      client_id: client_id,
      scope: "repo",
      state: state
    })

    redirect conn, external: authorization_url
  end

  def github_callback(conn, %{"state" => state, "code" => code}) do
    github_creds = Application.get_env(:slax, :github)

    access_token = Github.fetch_access_token(%{
      client_id: github_creds[:client_id],
      client_secret: github_creds[:client_secret],
      code: code,
      state: state
    })

    %{"login" => github_username} = Github.current_user_info(%{
      access_token: access_token
    })

    case Repo.get_by(User, slack_id: state) do
      nil -> %User{slack_id: state}
      user -> user
    end
    |> User.changeset(%{
      github_username: github_username,
      github_access_token: access_token
    })
    |> Repo.insert_or_update

    text conn, "Authentication successful! You can close this window."
  end
end
