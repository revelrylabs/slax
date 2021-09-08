defmodule SlaxWeb.Components.Hamburger do
  @moduledoc false
  use SlaxWeb, :component

  def render(assigns) do
    ~F"""
    <svg
      class="block h-6 w-6"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      aria-hidden="true"
    >
      <path
        x-cloak
        x-show="!mobileMenuOpen"
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M4 6h16M4 12h16M4 18h16"
      />
      <path
        x-cloak
        x-show="mobileMenuOpen"
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M6 18L18 6M6 6l12 12"
        style="display: none;"
      />
    </svg>
    """
  end
end
