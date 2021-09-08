defmodule SlaxWeb.LiveViews.Support do
  @moduledoc false
  use SlaxWeb, :live_view

  @impl true
  def mount(_, session, socket) do
    socket = assign_user_props(socket, session)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Page title="" signed_in={@signed_in} avatar={@avatar}>
      <Hero image="https://images.unsplash.com/photo-1520333789090-1afc82db536a?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=2102&q=80">
        <:title>Support</:title>
        <:body>Please Email us at <a href="mailto:support@slax.com">
            support@slax.com</a></:body>
      </Hero>
    </Page>
    """
  end
end
