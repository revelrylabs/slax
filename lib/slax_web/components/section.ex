defmodule SlaxWeb.Components.Section do
  @moduledoc false
  use SlaxWeb, :component

  prop title, :string, required: true
  slot default, required: true

  def render(assigns) do
    ~F"""
    <div class="border bg-white rounded-lg">
      <h2 class="font-bold border-b border-gray-100 p-5">{@title}</h2>
      <div class="p-4 space-y-6">
        <#slot />
      </div>
    </div>
    """
  end
end
