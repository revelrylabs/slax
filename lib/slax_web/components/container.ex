defmodule SlaxWeb.Components.Container do
  @moduledoc false
  use SlaxWeb, :component

  slot default, required: true
  prop centered, :boolean

  def render(assigns) do
    ~F"""
    <div class={"max-w-7xl mx-auto py-5 sm:px-6 lg:px-8 #{centered?(@centered)}"}>
      <#slot />
    </div>
    """
  end

  def centered?(true), do: "text-center"
  def centered?(_), do: nil
end
