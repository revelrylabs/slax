defmodule SlaxWeb.LiveViews.SetupStep1 do
  @moduledoc false
  use SlaxWeb, :live_view

  @impl true

  @spec mount(any, any, Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_, session, socket) do
    socket = assign_user_props(socket, session)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Page signed_in={@signed_in} avatar={@avatar} title="Get Started">
      <P>page 1 of 3</P>
      <:buttons>
        <Button>Back</Button>
        <Button href={Routes.live_path(@socket, SlaxWeb.LiveViews.SetupStep2)}>Next</Button>
      </:buttons>
      <H3>Hey there 👋 I'm PeerBot. Here are a few ways you can shoutout your teammates in Slack</H3>
      <P>1️⃣ Use the /slax command. Type /slax shoutout to give a shoutout to someone via Slack.</P>
      <P>2️⃣ Use the Shoutout action. Select Shoutout in a message's context menu.</P>
      <P>You can also type /slax help to see a list of commands.</P>
      <P>Try it out by using the /slax shoutout command in any channel!</P>
    </Page>
    """
  end
end
