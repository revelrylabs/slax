defmodule SlaxWeb.Components.Hero do
  @moduledoc """
  A component that represents a hero section.
  """

  use SlaxWeb, :component

  slot title
  slot body
  slot buttons
  prop image, :string, required: true

  def render(assigns) do
    ~F"""
    <main class="lg:relative">
      <div class="mx-auto max-w-7xl w-full pt-16 pb-20 text-center lg:py-48 lg:text-left">
        <div class="px-4 lg:w-1/2 sm:px-8 xl:pr-16">
          <h1 class="text-4xl tracking-tight font-extrabold text-gray-900 sm:text-5xl md:text-6xl lg:text-5xl xl:text-6xl">
            <span class="block xl:inline"><#slot name="title" /></span>
          </h1>
          <p class="mt-3 max-w-md mx-auto text-lg text-gray-500 sm:text-xl md:mt-5 md:max-w-3xl">
            <#slot name="body" />
          </p>
          <div class="mt-10 sm:flex sm:justify-center lg:justify-start space-x-3">
            <#slot name="buttons" />
          </div>
        </div>
      </div>
      <div class="relative w-full h-64 sm:h-72 md:h-96 lg:absolute lg:inset-y-0 lg:right-0 lg:w-1/2 lg:h-full">
        <img class="absolute inset-0 w-full h-full object-cover" src={@image} alt="">
      </div>
    </main>
    """
  end
end
