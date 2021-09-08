defmodule SlaxWeb.Components.Type.LI do
  @moduledoc false
  use SlaxWeb, :component

  slot default, required: true

  def render(assigns) do
    ~F"""
    <li class="text-md text-gray-500 list-outside ml-5">
      <#slot />
    </li>
    """
  end
end
