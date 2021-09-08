defmodule SlaxWeb.LiveViews.SetupStep3 do
  @moduledoc false
  use SlaxWeb, :live_view

  alias Slax.Slack.WelcomeMessage
  alias Slax.Teams

  @impl true
  def mount(_, session, socket) do
    socket =
      socket
      |> assign_user_props(session)
      |> assign_users_teams(session)
      |> assign(terms: false)
      |> assign(privacy: false)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Page signed_in={@signed_in} avatar={@avatar} title="Review Terms and Privacy Policy">
      <:buttons>
        <Button href={Routes.live_path(@socket, SlaxWeb.LiveViews.SetupStep2)}>Back</Button>
        <Button :if={@terms and @privacy} click="finish">Finish</Button>
      </:buttons>

      <H3>Please review and accept our Terms of Service and Privacy Policy</H3>
      <form :on-change="form">
        <label>
          <input checked={@terms} name="terms" type="checkbox">
          I agree to the Slax <a href={Routes.live_path(@socket, SlaxWeb.LiveViews.Terms)}>Terms of Service.</a>
        </label>
        <label>
          <input checked={@privacy} name="privacy" type="checkbox">
          I consent to the Slax <a href={Routes.live_path(@socket, SlaxWeb.LiveViews.Privacy)}>Privacy Policy</a>
        </label>
      </form>
    </Page>
    """
  end

  @impl true
  def handle_event("form", params, socket) do
    socket =
      socket
      |> assign(:terms, params["terms"] == "on")
      |> assign(:privacy, params["privacy"] == "on")

    {:noreply, socket}
  end

  def handle_event("finish", _, %{assigns: %{team_id: team_id}} = socket) do
    with team <- Teams.get_team(id: team_id),
         {:ok, _} <- Teams.update_team(team, %{onboarded_at: DateTime.utc_now()}) do
      maybe_add_welcome_message_job(team)
      path = Routes.live_path(socket, SlaxWeb.LiveViews.SetupSuccess)
      socket = push_redirect(socket, to: path)
      {:noreply, socket}
    end
  end

  defp maybe_add_welcome_message_job(%{
         send_welcome_message: true,
         welcome_channel_slack_id: welcome_channel_slack_id,
         token: token
       }) do
    attrs = %{welcome_channel_slack_id: welcome_channel_slack_id, token: token}

    attrs
    |> WelcomeMessage.new()
    |> Oban.insert()
  end

  defp maybe_add_welcome_message_job(_), do: nil
end
