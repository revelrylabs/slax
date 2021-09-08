defmodule SlaxWeb.LiveViews.Settings do
  @moduledoc """
  LiveView for showing settings.
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
    <Page signed_in={@signed_in} avatar={@avatar} title="Settings">
      <div class="divide-y">
        <ActionPanel
          title="Delete your account?"
          description="Doing so will permanently delete all data for your team. For safe measures, we've provided a link to download your teams data."
        >
          <Button click="delete-team">Delete Account</Button>
        </ActionPanel>
        <ActionPanel
          title="Download CSV"
          description="Clicking this link will download all the shoutouts for your organization."
        >
          <Button href={Routes.shoutout_path(@socket, :csv_download, @team_id)}>Download CSV</Button>
        </ActionPanel>
      </div>
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
