defmodule SlaxWeb.Components.PageFooter do
  @moduledoc false
  use SlaxWeb, :component

  def render(assigns) do
    ~F"""
    <Container>
      <div class="flex flex-row justify-between">
        <Logo />
        <div class="flex">
          <A href={Routes.live_path(@socket, SlaxWeb.LiveViews.Terms)}>Terms</A>
        </div>
      </div>
    </Container>
    """
  end
end
