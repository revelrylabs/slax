defmodule SlaxWeb.Components.Type.A do
  @moduledoc false
  use SlaxWeb, :component

  slot default, required: true
  prop href, :string, required: true

  def render(assigns) do
    ~F"""
    <a href={@href} class="text-purple-700 hover:text-purple-400">
      <#slot />
    </a>
    """
  end
end
