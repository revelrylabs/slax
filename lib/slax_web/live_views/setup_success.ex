defmodule SlaxWeb.LiveViews.SetupSuccess do
  @moduledoc """
  The final page a user sees upon successfully setting up Slax
  """
  use SlaxWeb, :live_view

  @impl true

  def mount(_, session, socket) do
    socket = assign_user_props(socket, session)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Page signed_in={@signed_in} avatar={@avatar}>
      <Container centered>
        <H2>🤖 Congratulations!</H2>
        <H3>You've added Slax to your Slack workspace.</H3>
        <P>Slax will be available in all channels in your workspace.</P>
        <Button href={Routes.live_path(@socket, SlaxWeb.LiveViews.Account)}>Go to Slax Dashboard</Button>
      </Container>
    </Page>
    """
  end
end
