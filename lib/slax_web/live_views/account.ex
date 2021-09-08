defmodule SlaxWeb.LiveViews.Account do
  @moduledoc false
  use SlaxWeb, :live_view

  alias Slax.Schemas.Team
  alias SlaxWeb.LiveViews.Account.Shoutout

  @impl true
  def mount(_, session, socket) do
    socket =
      socket
      |> assign_user_props(session)
      |> assign_users_teams(session)
      |> assign_all_shoutouts(page: 1, page_size: 10)
      |> assign_received_shoutouts(page: 1, page_size: 5)
      |> assign_given_shoutouts(page: 1, page_size: 5)

    Phoenix.PubSub.subscribe(Slax.PubSub, "new_shoutout_for_team_#{socket.assigns.team_id}")
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Page signed_in={@signed_in} avatar={@avatar} title={get_team_name(@teams, @team_id)}>
      <div class="flex flex-row">
        <div class="w-full mt-10 mb-10 mr-2 space-y-4" :if={show_empty_state(assigns)}>
          <SlaxWeb.Components.EmptyState slack_team_id={slack_team_id(assigns)} />
        </div>
        <div class="w-1/2 mr-2 space-y-4" :if={!show_empty_state(assigns)}>
          <Section title="Received">
            {#for shoutout <- @received_shoutouts}
              <Shoutout shoutout={shoutout} />
            {/for}
            <Pagination
              page_number={@received_shoutouts.page_number}
              page_size={@received_shoutouts.page_size}
              total_entries={@received_shoutouts.total_entries}
              previous={"received-previous-#{@received_shoutouts.page_number}"}
              next={"received-next-#{@received_shoutouts.page_number}"}
            />
          </Section>
          <Section title="Given" :if={!show_empty_state(assigns)}>
            {#for shoutout <- @given_shoutouts}
              <Shoutout shoutout={shoutout} />
            {/for}
            <Pagination
              page_number={@given_shoutouts.page_number}
              page_size={@given_shoutouts.page_size}
              total_entries={@given_shoutouts.total_entries}
              previous={"given-previous-#{@given_shoutouts.page_number}"}
              next={"given-next-#{@given_shoutouts.page_number}"}
            />
          </Section>
        </div>
        <div class="w-1/2 ml-2" :if={!show_empty_state(assigns)}>
          <Section title="All">
            {#for shoutout <- @all_shoutouts}
              <Shoutout shoutout={shoutout} />
            {/for}
            <Pagination
              page_number={@all_shoutouts.page_number}
              page_size={@all_shoutouts.page_size}
              total_entries={@all_shoutouts.total_entries}
              previous={"all-previous-#{@all_shoutouts.page_number}"}
              next={"all-next-#{@all_shoutouts.page_number}"}
            />
          </Section>
        </div>
      </div>
    </Page>
    """
  end

  @impl true
  def handle_event("all-previous-" <> page, _, socket) do
    {page, _} = Integer.parse(page)
    {:noreply, assign_all_shoutouts(socket, page: page - 1, page_size: 10)}
  end

  def handle_event("all-next-" <> page, _, socket) do
    {page, _} = Integer.parse(page)
    {:noreply, assign_all_shoutouts(socket, page: page + 1, page_size: 10)}
  end

  def handle_event("received-previous-" <> page, _, socket) do
    {page, _} = Integer.parse(page)
    {:noreply, assign_received_shoutouts(socket, page: page - 1, page_size: 5)}
  end

  def handle_event("received-next-" <> page, _, socket) do
    {page, _} = Integer.parse(page)
    {:noreply, assign_received_shoutouts(socket, page: page + 1, page_size: 5)}
  end

  def handle_event("given-previous-" <> page, _, socket) do
    {page, _} = Integer.parse(page)
    {:noreply, assign_given_shoutouts(socket, page: page - 1, page_size: 5)}
  end

  def handle_event("given-next-" <> page, _, socket) do
    {page, _} = Integer.parse(page)
    {:noreply, assign_given_shoutouts(socket, page: page + 1, page_size: 5)}
  end

  @impl true
  def handle_info({:update, shoutout}, %{assigns: %{user_id: user_id}} = socket) do
    socket =
      case shoutout.sender_id do
        ^user_id ->
          assign_given_shoutouts(socket, page: 1, page_size: 5)

        _ ->
          assign_received_shoutouts(socket, page: 1, page_size: 5)
      end

    {:noreply, assign_all_shoutouts(socket, page: 1, page_size: 10)}
  end

  defp get_team_name(teams, team_id) do
    case Enum.find(teams, &(&1.id == team_id)) do
      %Team{name: name} ->
        name

      _ ->
        nil
    end
  end

  defp show_empty_state(%{
         received_shoutouts: %{total_entries: 0},
         given_shoutouts: %{total_entries: 0},
         all_shoutouts: %{total_entries: 0}
       }),
       do: true

  defp show_empty_state(_), do: false

  defp slack_team_id(assigns) do
    assigns
    |> current_team()
    |> Map.get(:slack_id)
  end
end
