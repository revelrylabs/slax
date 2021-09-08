defmodule SlaxWeb.LiveViews.Styleguide do
  @moduledoc """
  View for showing the styleguide.
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
    <Page title="Styleguide" signed_in={@signed_in} avatar={@avatar}>
      <Hero image="https://images.unsplash.com/photo-1520333789090-1afc82db536a?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=2102&q=80">
        <:title>Data to enrich your online business</:title>
        <:body>Anim aute id magna aliqua ad ad non deserunt sunt. Qui irure qui lorem cupidatat commodo. Elit sunt amet fugiat veniam occaecat fugiat aliqua.</:body>
        <:buttons>
          <Button href="#">Get Started</Button>
          <Button href="#">Live Demo</Button>
        </:buttons>
      </Hero>

      <HR />

      <ActionPanel
        title="Are you sure you want to delete your account?"
        description="Doing so will permanently delete all data for your team. For safe measures, we've provided a link to download your teams data."
      >
        <Button>Delete Account</Button>
        <Button>Download Data</Button>
      </ActionPanel>

      <HR />

      <EmptyState slack_team_id="HND23232" />

      <HR />

      <H2>{Faker.Lorem.sentence(5)}</H2>
      <P>{Faker.Lorem.sentence(55)}</P>
      <H3>{Faker.Lorem.sentence(5)}</H3>

      <P>{Faker.Lorem.sentence(55)}</P>

      <OL>
        <LI>{Faker.Lorem.sentence(5)}</LI>
        <LI>{Faker.Lorem.sentence(5)}</LI>
        <LI>{Faker.Lorem.sentence(5)}</LI>
        <LI>{Faker.Lorem.sentence(5)}</LI>
        <LI>{Faker.Lorem.sentence(5)}</LI>
      </OL>

      <P>{Faker.Lorem.sentence(55)}</P>

      <UL>
        <LI>{Faker.Lorem.sentence(5)}</LI>
        <LI>{Faker.Lorem.sentence(5)}</LI>
        <LI>{Faker.Lorem.sentence(5)}</LI>
        <LI>{Faker.Lorem.sentence(5)}</LI>
        <LI>{Faker.Lorem.sentence(5)}</LI>
      </UL>

      <Button>Primary Button</Button>
    </Page>
    """
  end
end
