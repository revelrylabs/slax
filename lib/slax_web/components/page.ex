defmodule SlaxWeb.Components.Page do
  @moduledoc false
  use SlaxWeb, :component

  prop signed_in, :boolean, default: false
  prop avatar, :string, default: nil
  prop title, :string, default: nil
  slot default, required: true
  slot buttons, required: false

  def render(assigns) do
    ~F"""
    <div x-data="{ mobileMenuOpen: false }">
      <div class="bg-gray-800 pb-32">
        <nav>
          <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="border-b border-gray-700">
              <div class="flex items-center justify-between h-16 px-4 sm:px-0">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <Logo />
                  </div>
                </div>

                <div class="ml-4 flex items-center md:ml-6">
                  <div class="ml-3 relative">
                    <div>
                      <button
                        class={dropdown_button_styles(@signed_in)}
                        @click="mobileMenuOpen = !mobileMenuOpen"
                        x-bind:aria-expanded="mobileMenuOpen ? 'true' : 'false'"
                      >
                        {#if @signed_in}
                          <img class="h-8 w-8 rounded-full" src={@avatar} alt="">
                        {#else}
                          <Hamburger />
                        {/if}
                      </button>
                    </div>

                    <div
                      id="mobile-menu"
                      x-show="mobileMenuOpen"
                      phx-update="ignore"
                      class="origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg py-1 bg-white ring-1 ring-black ring-opacity-5 focus:outline-none"
                    >
                      {#if @signed_in}
                        <a
                          href={Routes.live_path(@socket, SlaxWeb.LiveViews.Account)}
                          class="block px-4 py-2 text-sm text-gray-700"
                        >Dashboard</a>
                        <a
                          href={Routes.live_path(@socket, SlaxWeb.LiveViews.Settings)}
                          class="block px-4 py-2 text-sm text-gray-700"
                        >Settings</a>
                        <a href={Routes.slack_path(@socket, :sign_out)} class="block px-4 py-2 text-sm text-gray-700">Sign Out</a>
                      {#else}
                        <a href="#" class="block px-4 py-2 text-sm text-gray-700">About</a>
                        <a href={login_to_slack_url()} class="block px-4 py-2 text-sm text-gray-700">Sign In</a>
                      {/if}
                      <a
                        href={Routes.live_path(@socket, SlaxWeb.LiveViews.Support)}
                        class="block px-4 py-2 text-sm text-gray-700"
                      >Support</a>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </nav>
        {#unless is_nil(@title)}
          <header class="py-10" x-data="{smallScreen:false}">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
              <div class="flex flex-col md:flex-row justify-between">
                <h1 class="text-3xl font-bold text-white mb-3 md:mb-0">{@title}</h1>
                <div>
                  <#slot name="buttons" />
                </div>
              </div>
            </div>
          </header>
        {/unless}
      </div>
      <main class="-mt-32">
        <div class="max-w-7xl mx-auto pb-12 px-4 sm:px-6 lg:px-8">
          <div class="bg-white rounded-lg shadow px-5 py-6 sm:px-6">
            <div class="border-gray-200 rounded-lg">
              <#slot />
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  defp dropdown_button_styles(true) do
    "max-w-xs bg-gray-800 rounded-full flex items-center text-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-white"
  end

  defp dropdown_button_styles(false) do
    "inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-white hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white"
  end
end
