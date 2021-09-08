defmodule SlaxWeb.Components.Button do
  @moduledoc """
  Button component.
  """
  use SlaxWeb, :component

  prop disable_with, :string
  prop click, :event
  prop confirm, :string
  prop href, :string
  slot default, required: true

  def render(assigns) do
    ~F"""
    <a
      :on-click={@click}
      data-confirm={@confirm}
      class={classes()}
      phx-disable-with={@disable_with}
      href={@href}
    >
      <#slot />
    </a>
    """
  end

  defp classes do
    """
      inline-flex items-center px-4 py-2 border border-transparent text-sm font-smaller
      rounded-md shadow-sm text-white bg-gray-600 hover:bg-gray-700 focus:outline-none
      focus:ring-2 focus:ring-offset-2 focus:ring-gray-500
      cursor-pointer
    """
  end
end
