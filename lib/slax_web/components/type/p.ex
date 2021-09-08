defmodule SlaxWeb.Components.Type.P do
  @moduledoc false
  use SlaxWeb, :component

  slot default, required: true

  def render(assigns) do
    ~F"""
    <p class="text-md text-gray-500 my-5">
      <#slot />
    </p>
    """
  end
end
