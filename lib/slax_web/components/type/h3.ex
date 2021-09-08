defmodule SlaxWeb.Components.Type.H3 do
  @moduledoc false
  use SlaxWeb, :component

  slot default, required: true

  def render(assigns) do
    ~F"""
    <h3 class="text-2xl my-5">
      <#slot />
    </h3>
    """
  end
end
