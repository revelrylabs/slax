defmodule SlaxWeb.Components.Logo do
  @moduledoc false
  use SlaxWeb, :component

  def render(assigns) do
    ~F"""
    <h1 class="leading-tight font-bold text-xl text-white">
      <a href={Routes.live_path(@socket, SlaxWeb.LiveViews.Home)}>slax</a>
    </h1>
    """
  end
end
