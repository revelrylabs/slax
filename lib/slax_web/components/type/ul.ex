defmodule SlaxWeb.Components.Type.UL do
  @moduledoc false
  use SlaxWeb, :component

  slot default, required: true

  def render(assigns) do
    ~F"""
    <ul class="list-disc my-5">
      <#slot />
    </ul>
    """
  end
end
