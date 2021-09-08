defmodule SlaxWeb.LiveViews.Helpers do
  @moduledoc false
  import Phoenix.LiveView, only: [assign: 3]

  alias Slax.Shoutouts
  alias Slax.Teams
  alias Slax.Users

  @spec assign_users_teams(Phoenix.LiveView.Socket.t(), map) :: Phoenix.LiveView.Socket.t()
  def assign_users_teams(socket, %{"user_id" => user_id}) do
    teams = Teams.list_teams(user_id: user_id)

    socket
    |> assign(:teams, teams)
    |> assign(:team_id, Map.get(List.first(teams), :id))
  end

  @spec assign_user_props(Phoenix.LiveView.Socket.t(), any) :: Phoenix.LiveView.Socket.t()
  def assign_user_props(socket, %{"user_id" => user_id}) do
    user = Users.get_user(id: user_id)

    if is_nil(user) do
      socket
      |> assign(:avatar, nil)
      |> assign(:signed_in, false)
      |> assign(:user_id, nil)
    else
      socket
      |> assign(:avatar, Map.get(user, :avatar))
      |> assign(:signed_in, true)
      |> assign(:user_id, user_id)
    end
  end

  def assign_user_props(socket, _) do
    socket
    |> assign(:avatar, nil)
    |> assign(:signed_in, false)
    |> assign(:user_id, nil)
  end

  @spec assign_all_shoutouts(Phoenix.LiveView.Socket.t(), %{
          optional(:page) => integer,
          optional(:page_size) => integer
        }) :: Phoenix.LiveView.Socket.t()
  def assign_all_shoutouts(%{assigns: %{team_id: team_id}} = socket, page_params) do
    shoutouts = Shoutouts.page_shoutouts([team_id: team_id], page_params)
    assign(socket, :all_shoutouts, shoutouts)
  end

  @spec assign_received_shoutouts(Phoenix.LiveView.Socket.t(), %{
          optional(:page) => integer,
          optional(:page_size) => integer
        }) :: Phoenix.LiveView.Socket.t()
  def assign_received_shoutouts(%{assigns: %{user_id: user_id}} = socket, page_params) do
    shoutouts = Shoutouts.page_shoutouts([receiver: user_id], page_params)
    assign(socket, :received_shoutouts, shoutouts)
  end

  @spec assign_given_shoutouts(Phoenix.LiveView.Socket.t(), %{
          optional(:page) => integer,
          optional(:page_size) => integer
        }) :: Phoenix.LiveView.Socket.t()
  def assign_given_shoutouts(%{assigns: %{user_id: user_id}} = socket, page_params) do
    shoutouts = Shoutouts.page_shoutouts([sender_id: user_id], page_params)
    assign(socket, :given_shoutouts, shoutouts)
  end

  @spec install_slack_app_url :: binary()
  def install_slack_app_url do
    params = %{
      "user_scope" => "users.profile:read",
      "scope" => "app_mentions:read,commands,users.profile:read,chat:write",
      "client_id" => slack_client_id()
    }

    "https://slack.com/oauth/v2/authorize"
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(params))
    |> URI.to_string()
  end

  @spec login_to_slack_url :: binary()
  def login_to_slack_url do
    params = %{
      "user_scope" => "users.profile:read",
      "client_id" => slack_client_id()
    }

    "https://slack.com/oauth/v2/authorize"
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(params))
    |> URI.to_string()
  end

  @spec slack_client_id :: binary()
  def slack_client_id do
    :slax
    |> Application.get_env(Slax.Slack)
    |> Keyword.get(:client_id)
  end

  @spec current_team(%{teams: [], team_id: []}) :: Slax.Schemas.Team.t()
  def current_team(%{teams: teams, team_id: team_id}) do
    Enum.find(teams, &(&1.id == team_id))
  end
end
