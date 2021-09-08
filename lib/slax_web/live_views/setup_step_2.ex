defmodule SlaxWeb.LiveViews.SetupStep2 do
  @moduledoc false
  use SlaxWeb, :live_view

  alias Slax.Slack.Request
  alias Slax.Teams

  data send_welcome_message, :boolean, default: false
  data channels, :list, default: []
  data channel_id, :string, default: nil

  @impl true
  def mount(_, session, socket) do
    socket =
      socket
      |> assign_user_props(session)
      |> assign_users_teams(session)

    send(self(), :fetch_channels)
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Page signed_in={@signed_in} avatar={@avatar} title="Get Started">
      <P>page 2 of 3</P>
      <:buttons>
        <Button href={Routes.live_path(@socket, SlaxWeb.LiveViews.SetupStep1)}>Back</Button>
        <Button click="next">Next</Button>
      </:buttons>
      <H3>Would you like Slax to send a welcome message to the channels in your workspace?</H3>
      <form :on-change="form">
        <div>
          <label>
            Select Channel
            <select name="channel_id">
              <option value="">Select Channel</option>
              {#for channel <- @channels}
                <option value={channel["id"]}>{channel["name"]}</option>
              {/for}
            </select>
          </label>
        </div>
        <div>
          <input
            id="welcome-message-yes"
            type="radio"
            name="send"
            value="yes"
            checked={@send_welcome_message}
          />
          <label for="welcome-message-yes">Yes (recommended)</label>
        </div>
        <div>
          <input
            id="welcome-message-no"
            type="radio"
            name="send"
            value="no"
            checked={!@send_welcome_message}
          />
          <label for="welcome-message-no">No</label>
        </div>
      </form>
    </Page>
    """
  end

  @impl true
  def handle_info(:fetch_channels, %{assigns: %{teams: teams, team_id: team_id}} = socket) do
    team = Enum.find(teams, &(&1.id == team_id))
    {:ok, %{"channels" => channels}, _} = Request.get("conversations.list", %{}, team.token)
    channels = Enum.map(channels, &Map.take(&1, ["id", "name"]))
    {:noreply, assign(socket, :channels, channels)}
  end

  @impl true
  def handle_event("form", %{"channel_id" => channel_id, "send" => send}, socket) do
    socket =
      socket
      |> assign(:send_welcome_message, send == "yes")
      |> assign(:channel_id, channel_id)

    {:noreply, socket}
  end

  def handle_event(
        "next",
        _,
        %{
          assigns: %{
            send_welcome_message: send_welcome_message,
            channel_id: channel_id,
            teams: teams,
            team_id: team_id
          }
        } = socket
      ) do
    {:ok, _} =
      teams
      |> Enum.find(&(&1.id == team_id))
      |> Teams.update_team(%{
        send_welcome_message: send_welcome_message,
        welcome_channel_slack_id: channel_id
      })

    {:noreply, push_redirect(socket, to: Routes.live_path(socket, SlaxWeb.LiveViews.SetupStep3))}
  end
end
