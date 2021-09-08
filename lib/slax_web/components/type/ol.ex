defmodule SlaxWeb.Components.Type.OL do
  @moduledoc false
  use SlaxWeb, :component

  slot default, required: true

  def render(assigns) do
    ~F"""
    <ol class="list-decimal my-5">
      <#slot />
    </ol>
    """
  end
end
