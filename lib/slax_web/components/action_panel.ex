defmodule SlaxWeb.Components.ActionPanel do
  @moduledoc false

  use SlaxWeb, :component

  prop title, :string
  prop description, :string
  slot default

  def render(assigns) do
    ~F"""
    <div class="bg-white">
      <div class="px-4 py-5 sm:p-6">
        <div class="sm:flex sm:items-start sm:justify-between">
          <div>
            <h3 class="text-lg leading-6 font-medium text-gray-900">
              {@title}
            </h3>
            <div class="mt-2 max-w-xl text-sm text-gray-500">
              <p>
                {@description}
              </p>
            </div>
          </div>
          <div class="mt-5 sm:mt-0 sm:ml-6 sm:flex-shrink-0 sm:flex sm:items-center">
            <#slot />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
