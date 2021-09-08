defmodule SlaxWeb.Components.Type.H2 do
  @moduledoc false
  use SlaxWeb, :component

  slot default, required: true

  def render(assigns) do
    ~F"""
    <h2 class="text-3xl my-5">
      <#slot />
    </h2>
    """
  end
end
