defmodule SlaxWeb.SlackController do
  use SlaxWeb, :controller

  require Logger

  alias Slax.Account
  alias Slax.Schemas.Team
  alias Slax.Slack.Messages
  alias Slax.Slack.Request

  def auth(conn, params) do
    with {:ok, auth, 200} <- obtain_access(params),
         {:ok, user, 200} <- fetch_user_data(auth),
         {:ok, auth} <- get_auth_params(auth, user),
         {:ok, %{user: %{id: user_id}, team: team}} <- Account.authenticate(auth) do
      conn
      |> put_session(:user_id, user_id)
      |> put_flash(:info, "Success.")
      |> auth_redirect(team)
    else
      {:error, :team, _, _} ->
        conn
        |> put_flash(:error, "You need to install the app in a slack workspace.")
        |> redirect(to: Routes.live_path(conn, SlaxWeb.LiveViews.Home))

      error ->
        Logger.warn("Authentication Error: #{inspect(error)}")

        conn
        |> put_flash(:error, "Error while trying to authenticate.")
        |> redirect(to: Routes.live_path(conn, SlaxWeb.LiveViews.Home))
    end
  end

  def sign_out(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: Routes.live_path(conn, SlaxWeb.LiveViews.Home))
  end

  def message(conn, %{"type" => "url_verification", "challenge" => challenge}) do
    text(conn, challenge)
  end

  def message(conn, params) do
    with :ok <- Messages.handle_message(params) do
      send_resp(conn, 200, "")
    end
  end

  # Private Functions
  defp auth_redirect(conn, %Team{onboarded_at: nil}) do
    redirect(conn, to: Routes.live_path(conn, SlaxWeb.LiveViews.SetupStep1))
  end

  defp auth_redirect(conn, _) do
    redirect(conn, to: Routes.live_path(conn, SlaxWeb.LiveViews.Account))
  end

  defp get_auth_params(
         %{
           "authed_user" => %{"id" => slack_sender_id, "access_token" => user_token},
           "team" => %{"id" => slack_team_id, "name" => team_name},
           "access_token" => bot_token,
           "token_type" => "bot"
         },
         %{
           "ok" => true,
           "profile" => %{"display_name" => user_name, "image_192" => avatar}
         }
       ) do
    {:ok,
     %{
       team: %{slack_id: slack_team_id, name: team_name, token: bot_token},
       user: %{
         slack_id: slack_sender_id,
         name: user_name,
         avatar: avatar,
         token: user_token
       }
     }}
  end

  defp get_auth_params(
         %{
           "authed_user" => %{
             "id" => slack_sender_id,
             "token_type" => "user",
             "access_token" => user_token
           },
           "team" => %{"id" => slack_team_id, "name" => team_name}
         },
         %{
           "ok" => true,
           "profile" => %{"display_name" => user_name, "image_192" => avatar}
         }
       ) do
    {:ok,
     %{
       team: %{slack_id: slack_team_id, name: team_name},
       user: %{
         slack_id: slack_sender_id,
         name: user_name,
         avatar: avatar,
         token: user_token
       }
     }}
  end

  defp get_auth_params(auth, user),
    do: {:error, "Unable to parse params necessary to sign in.", auth, user}

  defp obtain_access(params) do
    config = Application.get_env(:slax, Slax.Slack)

    Request.get("oauth.v2.access", %{
      client_id: config[:client_id],
      client_secret: config[:client_secret],
      code: Map.get(params, "code")
    })
  end

  defp fetch_user_data(%{"authed_user" => %{"id" => user_id, "access_token" => token}}) do
    Request.get("users.profile.get", %{user: user_id}, token)
  end

  defp fetch_user_data(_), do: {:error, "Unabled to fetch user data."}
end
