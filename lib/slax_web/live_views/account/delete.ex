defmodule SlaxWeb.LiveViews.Account.Delete do
  @moduledoc """
  LiveView for confirming deletion of your account
  """
  use SlaxWeb, :live_view

  alias Slax.Teams

  @impl true
  def mount(_, session, socket) do
    socket =
      socket
      |> assign_user_props(session)
      |> assign_users_teams(session)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Page signed_in={@signed_in} avatar={@avatar}>
      <H3>Deleting your account will also delete:</H3>
      <OL>
        <LI>all shoutouts for your team</LI>
        <LI>all users not associated with other teams</LI>
      </OL>
      <br><hr><br>
      <UL>
        <LI>click here if you would like to download a CSV of all shoutouts before deleting your profile:
          <Button>Download CSV</Button>
        </LI>
        <LI>When you're ready: <Button click="delete-team" confirm="Are you really sure?">Delete My Account</Button></LI>
      </UL>
    </Page>
    """
  end

  @impl true
  def handle_event("delete-team", _, %{assigns: %{team_id: team_id}} = socket) do
    with {:ok, _} <- Teams.delete_team(team_id) do
      {:noreply, push_redirect(socket, to: Routes.slack_path(socket, :sign_out))}
    end
  end
end
