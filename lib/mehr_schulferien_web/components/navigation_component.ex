defmodule MehrSchulferienWeb.NavigationComponent do
  use Phoenix.Component

  alias MehrSchulferienWeb.NavigationHelper

  @doc """
  Renders the main navigation header for LiveView pages.

  ## Example
      <.navigation socket={@socket} conn={@conn} today={~D[2025-06-23]} />
  """
  attr :socket, :any, default: nil
  attr :conn, :any, default: nil
  attr :today, Date, required: true

  def navigation(assigns) do
    {current_year, next_year} = NavigationHelper.get_navigation_years(assigns.today)

    assigns = Map.merge(assigns, %{current_year: current_year, next_year: next_year})

    ~H"""
    <header class="bg-white dark:bg-gray-800 border-b border-slate-200 dark:border-gray-700">
      <nav class="mx-auto flex max-w-7xl items-center justify-between p-6 lg:px-8" aria-label="Global">
        <div class="flex lg:flex-1">
          <a href="/" class="-m-1.5 p-1.5 flex items-center">
            <span class="sr-only">Mehr Schulferien</span>
            <div class="flex items-center">
              <div class="bg-blue-600 dark:bg-blue-500 text-white font-bold px-3 py-1 rounded-md flex items-center">
                <span class="text-lg tracking-wide">MEHR!</span>
              </div>
              <div class="ml-2 text-black dark:text-white font-black text-2xl">
                <span class="italic">Schulferien</span>
              </div>
            </div>
          </a>
        </div>
        <!-- Mobile menu button -->
        <div class="flex lg:hidden">
          <button
            type="button"
            class="mobile-menu-toggle -m-2.5 inline-flex items-center justify-center rounded-md p-2.5 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
          >
            <span class="sr-only">Open main menu</span>
            <svg
              class="size-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              aria-hidden="true"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
              />
            </svg>
          </button>
        </div>
        <!-- Desktop navigation -->
        <div class="hidden lg:flex lg:gap-x-12">
          <!-- Schulferien 2025 dropdown -->
          <div class="dropdown-container relative">
            <button
              type="button"
              class="dropdown-trigger flex items-center gap-x-1 text-sm/6 font-semibold text-gray-900 dark:text-gray-100"
            >
              Schulferien {@current_year}
              <svg
                class="size-5 flex-none text-gray-400 dark:text-gray-500"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fill-rule="evenodd"
                  d="M5.22 8.22a.75.75 0 0 1 1.06 0L10 11.94l3.72-3.72a.75.75 0 1 1 1.06 1.06l-4.25 4.25a.75.75 0 0 1-1.06 0L5.22 9.28a.75.75 0 0 1 0-1.06Z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
            <div class="dropdown-menu absolute top-full -left-8 z-10 mt-3 w-64 overflow-hidden rounded-3xl bg-white dark:bg-gray-800 shadow-lg ring-1 ring-gray-900/5 dark:ring-gray-700 opacity-0 invisible transition-all duration-200">
              <div class="p-2">
                <%= for {federal_state, display_name} <- NavigationHelper.federal_states() do %>
                  <a
                    href={"/ferien/d/bundesland/#{federal_state}/#{@current_year}"}
                    class="block rounded-lg px-3 py-1.5 text-sm font-semibold text-gray-900 dark:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700"
                  >
                    {display_name}
                  </a>
                <% end %>
              </div>
            </div>
          </div>
          <!-- Schulferien 2026 dropdown -->
          <div class="dropdown-container relative">
            <button
              type="button"
              class="dropdown-trigger flex items-center gap-x-1 text-sm/6 font-semibold text-gray-900 dark:text-gray-100"
            >
              Schulferien {@next_year}
              <svg
                class="size-5 flex-none text-gray-400 dark:text-gray-500"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fill-rule="evenodd"
                  d="M5.22 8.22a.75.75 0 0 1 1.06 0L10 11.94l3.72-3.72a.75.75 0 1 1 1.06 1.06l-4.25 4.25a.75.75 0 0 1-1.06 0L5.22 9.28a.75.75 0 0 1 0-1.06Z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
            <div class="dropdown-menu absolute top-full -left-8 z-10 mt-3 w-64 overflow-hidden rounded-3xl bg-white dark:bg-gray-800 shadow-lg ring-1 ring-gray-900/5 dark:ring-gray-700 opacity-0 invisible transition-all duration-200">
              <div class="p-2">
                <%= for {federal_state, display_name} <- NavigationHelper.federal_states() do %>
                  <a
                    href={"/ferien/d/bundesland/#{federal_state}/#{@next_year}"}
                    class="block rounded-lg px-3 py-1.5 text-sm font-semibold text-gray-900 dark:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700"
                  >
                    {display_name}
                  </a>
                <% end %>
              </div>
            </div>
          </div>
          <!-- Brückentage 2025 dropdown -->
          <div class="dropdown-container relative">
            <button
              type="button"
              class="dropdown-trigger flex items-center gap-x-1 text-sm/6 font-semibold text-gray-900 dark:text-gray-100"
            >
              Brückentage {@current_year}
              <svg
                class="size-5 flex-none text-gray-400 dark:text-gray-500"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fill-rule="evenodd"
                  d="M5.22 8.22a.75.75 0 0 1 1.06 0L10 11.94l3.72-3.72a.75.75 0 1 1 1.06 1.06l-4.25 4.25a.75.75 0 0 1-1.06 0L5.22 9.28a.75.75 0 0 1 0-1.06Z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
            <div class="dropdown-menu absolute top-full -left-8 z-10 mt-3 w-64 overflow-hidden rounded-3xl bg-white dark:bg-gray-800 shadow-lg ring-1 ring-gray-900/5 dark:ring-gray-700 opacity-0 invisible transition-all duration-200">
              <div class="p-2">
                <%= for {federal_state, display_name} <- NavigationHelper.federal_states() do %>
                  <a
                    href={"/brueckentage/d/bundesland/#{federal_state}/#{@current_year}"}
                    class="block rounded-lg px-3 py-1.5 text-sm font-semibold text-gray-900 dark:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700"
                  >
                    {display_name}
                  </a>
                <% end %>
              </div>
            </div>
          </div>
          <!-- Brückentage 2026 dropdown -->
          <div class="dropdown-container relative">
            <button
              type="button"
              class="dropdown-trigger flex items-center gap-x-1 text-sm/6 font-semibold text-gray-900 dark:text-gray-100"
            >
              Brückentage {@next_year}
              <svg
                class="size-5 flex-none text-gray-400 dark:text-gray-500"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fill-rule="evenodd"
                  d="M5.22 8.22a.75.75 0 0 1 1.06 0L10 11.94l3.72-3.72a.75.75 0 1 1 1.06 1.06l-4.25 4.25a.75.75 0 0 1-1.06 0L5.22 9.28a.75.75 0 0 1 0-1.06Z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
            <div class="dropdown-menu absolute top-full -left-8 z-10 mt-3 w-64 overflow-hidden rounded-3xl bg-white dark:bg-gray-800 shadow-lg ring-1 ring-gray-900/5 dark:ring-gray-700 opacity-0 invisible transition-all duration-200">
              <div class="p-2">
                <%= for {federal_state, display_name} <- NavigationHelper.federal_states() do %>
                  <a
                    href={"/brueckentage/d/bundesland/#{federal_state}/#{@next_year}"}
                    class="block rounded-lg px-3 py-1.5 text-sm font-semibold text-gray-900 dark:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700"
                  >
                    {display_name}
                  </a>
                <% end %>
              </div>
            </div>
          </div>
        </div>
        <!-- Mobile menu (simplified, hidden by default) -->
        <div class="mobile-menu hidden lg:hidden fixed inset-0 z-50 bg-white dark:bg-gray-900">
          <div class="px-6 py-6">
            <div class="flex items-center justify-between">
              <a href="/" class="-m-1.5 p-1.5">
                <span class="sr-only">Mehr Schulferien</span>
                <div class="flex items-center">
                  <div class="bg-blue-600 text-white font-bold px-3 py-1 rounded-md flex items-center">
                    <span class="text-lg tracking-wide">MEHR!</span>
                  </div>
                  <div class="ml-2 text-black font-black text-2xl">
                    <span class="italic">Schulferien</span>
                  </div>
                </div>
              </a>
              <button
                type="button"
                class="mobile-menu-close -m-2.5 rounded-md p-2.5 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
              >
                <span class="sr-only">Close menu</span>
                <svg
                  class="size-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
            <div class="mt-6 space-y-2">
              <details class="mobile-dropdown">
                <summary class="font-semibold text-gray-900 dark:text-gray-100 py-2 cursor-pointer">
                  Schulferien {@current_year}
                </summary>
                <div class="ml-4 space-y-1">
                  <%= for {federal_state, display_name} <- NavigationHelper.federal_states() do %>
                    <a
                      href={"/ferien/d/bundesland/#{federal_state}/#{@current_year}"}
                      class="block py-1 text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100"
                    >
                      {display_name}
                    </a>
                  <% end %>
                </div>
              </details>
              <details class="mobile-dropdown">
                <summary class="font-semibold text-gray-900 dark:text-gray-100 py-2 cursor-pointer">
                  Schulferien {@next_year}
                </summary>
                <div class="ml-4 space-y-1">
                  <%= for {federal_state, display_name} <- NavigationHelper.federal_states() do %>
                    <a
                      href={"/ferien/d/bundesland/#{federal_state}/#{@next_year}"}
                      class="block py-1 text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100"
                    >
                      {display_name}
                    </a>
                  <% end %>
                </div>
              </details>
              <details class="mobile-dropdown">
                <summary class="font-semibold text-gray-900 dark:text-gray-100 py-2 cursor-pointer">
                  Brückentage {@current_year}
                </summary>
                <div class="ml-4 space-y-1">
                  <%= for {federal_state, display_name} <- NavigationHelper.federal_states() do %>
                    <a
                      href={"/brueckentage/d/bundesland/#{federal_state}/#{@current_year}"}
                      class="block py-1 text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100"
                    >
                      {display_name}
                    </a>
                  <% end %>
                </div>
              </details>
              <details class="mobile-dropdown">
                <summary class="font-semibold text-gray-900 dark:text-gray-100 py-2 cursor-pointer">
                  Brückentage {@next_year}
                </summary>
                <div class="ml-4 space-y-1">
                  <%= for {federal_state, display_name} <- NavigationHelper.federal_states() do %>
                    <a
                      href={"/brueckentage/d/bundesland/#{federal_state}/#{@next_year}"}
                      class="block py-1 text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100"
                    >
                      {display_name}
                    </a>
                  <% end %>
                </div>
              </details>
            </div>
          </div>
        </div>
      </nav>
    </header>

    <style>
      /* CSS-only dropdown behavior */
      .dropdown-container:hover .dropdown-menu {
        opacity: 1;
        visibility: visible;
      }

      /* Simple mobile menu toggle */
      .mobile-menu-toggle.active + .mobile-menu {
        display: block;
      }
    </style>

    <script>
      // Simple vanilla JS for mobile menu toggle
      document.addEventListener('DOMContentLoaded', function() {
        const toggleBtn = document.querySelector('.mobile-menu-toggle');
        const closeBtn = document.querySelector('.mobile-menu-close');
        const mobileMenu = document.querySelector('.mobile-menu');

        if (toggleBtn && mobileMenu) {
          toggleBtn.addEventListener('click', function() {
            mobileMenu.classList.remove('hidden');
          });
        }

        if (closeBtn && mobileMenu) {
          closeBtn.addEventListener('click', function() {
            mobileMenu.classList.add('hidden');
          });
        }
      });
    </script>
    """
  end
end
