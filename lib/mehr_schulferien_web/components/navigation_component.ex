defmodule MehrSchulferienWeb.NavigationComponent do
  use Phoenix.Component

  @doc """
  Renders the main navigation header for LiveView pages.

  ## Example
      <.navigation socket={@socket} conn={@conn} />
  """
  attr :socket, :any, default: nil
  attr :conn, :any, default: nil

  def navigation(assigns) do
    ~H"""
    <header class="bg-white border-b border-slate-200">
      <nav class="mx-auto flex max-w-7xl items-center justify-between p-6 lg:px-8" aria-label="Global">
        <div class="flex lg:flex-1">
          <a href="/" class="-m-1.5 p-1.5 flex items-center">
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
        </div>
        <!-- Mobile menu button -->
        <div class="flex lg:hidden">
          <button
            type="button"
            class="mobile-menu-toggle -m-2.5 inline-flex items-center justify-center rounded-md p-2.5 text-gray-700"
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
              class="dropdown-trigger flex items-center gap-x-1 text-sm/6 font-semibold text-gray-900"
            >
              Schulferien 2025
              <svg class="size-5 flex-none text-gray-400" viewBox="0 0 20 20" fill="currentColor">
                <path
                  fill-rule="evenodd"
                  d="M5.22 8.22a.75.75 0 0 1 1.06 0L10 11.94l3.72-3.72a.75.75 0 1 1 1.06 1.06l-4.25 4.25a.75.75 0 0 1-1.06 0L5.22 9.28a.75.75 0 0 1 0-1.06Z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
            <div class="dropdown-menu absolute top-full -left-8 z-10 mt-3 w-64 overflow-hidden rounded-3xl bg-white shadow-lg ring-1 ring-gray-900/5 opacity-0 invisible transition-all duration-200">
              <div class="p-2">
                <%= for {federal_state, display_name} <- federal_states() do %>
                  <a
                    href={"/ferien/d/bundesland/#{federal_state}/2025"}
                    class="block rounded-lg px-3 py-1.5 text-sm font-semibold text-gray-900 hover:bg-gray-50"
                  >
                    <%= display_name %>
                  </a>
                <% end %>
              </div>
            </div>
          </div>
          <!-- Schulferien 2026 dropdown -->
          <div class="dropdown-container relative">
            <button
              type="button"
              class="dropdown-trigger flex items-center gap-x-1 text-sm/6 font-semibold text-gray-900"
            >
              Schulferien 2026
              <svg class="size-5 flex-none text-gray-400" viewBox="0 0 20 20" fill="currentColor">
                <path
                  fill-rule="evenodd"
                  d="M5.22 8.22a.75.75 0 0 1 1.06 0L10 11.94l3.72-3.72a.75.75 0 1 1 1.06 1.06l-4.25 4.25a.75.75 0 0 1-1.06 0L5.22 9.28a.75.75 0 0 1 0-1.06Z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
            <div class="dropdown-menu absolute top-full -left-8 z-10 mt-3 w-64 overflow-hidden rounded-3xl bg-white shadow-lg ring-1 ring-gray-900/5 opacity-0 invisible transition-all duration-200">
              <div class="p-2">
                <%= for {federal_state, display_name} <- federal_states() do %>
                  <a
                    href={"/ferien/d/bundesland/#{federal_state}/2026"}
                    class="block rounded-lg px-3 py-1.5 text-sm font-semibold text-gray-900 hover:bg-gray-50"
                  >
                    <%= display_name %>
                  </a>
                <% end %>
              </div>
            </div>
          </div>
          <!-- Brückentage 2025 dropdown -->
          <div class="dropdown-container relative">
            <button
              type="button"
              class="dropdown-trigger flex items-center gap-x-1 text-sm/6 font-semibold text-gray-900"
            >
              Brückentage 2025
              <svg class="size-5 flex-none text-gray-400" viewBox="0 0 20 20" fill="currentColor">
                <path
                  fill-rule="evenodd"
                  d="M5.22 8.22a.75.75 0 0 1 1.06 0L10 11.94l3.72-3.72a.75.75 0 1 1 1.06 1.06l-4.25 4.25a.75.75 0 0 1-1.06 0L5.22 9.28a.75.75 0 0 1 0-1.06Z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
            <div class="dropdown-menu absolute top-full -left-8 z-10 mt-3 w-64 overflow-hidden rounded-3xl bg-white shadow-lg ring-1 ring-gray-900/5 opacity-0 invisible transition-all duration-200">
              <div class="p-2">
                <%= for {federal_state, display_name} <- federal_states() do %>
                  <a
                    href={"/brueckentage/d/bundesland/#{federal_state}/2025"}
                    class="block rounded-lg px-3 py-1.5 text-sm font-semibold text-gray-900 hover:bg-gray-50"
                  >
                    <%= display_name %>
                  </a>
                <% end %>
              </div>
            </div>
          </div>
          <!-- Brückentage 2026 dropdown -->
          <div class="dropdown-container relative">
            <button
              type="button"
              class="dropdown-trigger flex items-center gap-x-1 text-sm/6 font-semibold text-gray-900"
            >
              Brückentage 2026
              <svg class="size-5 flex-none text-gray-400" viewBox="0 0 20 20" fill="currentColor">
                <path
                  fill-rule="evenodd"
                  d="M5.22 8.22a.75.75 0 0 1 1.06 0L10 11.94l3.72-3.72a.75.75 0 1 1 1.06 1.06l-4.25 4.25a.75.75 0 0 1-1.06 0L5.22 9.28a.75.75 0 0 1 0-1.06Z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
            <div class="dropdown-menu absolute top-full -left-8 z-10 mt-3 w-64 overflow-hidden rounded-3xl bg-white shadow-lg ring-1 ring-gray-900/5 opacity-0 invisible transition-all duration-200">
              <div class="p-2">
                <%= for {federal_state, display_name} <- federal_states() do %>
                  <a
                    href={"/brueckentage/d/bundesland/#{federal_state}/2026"}
                    class="block rounded-lg px-3 py-1.5 text-sm font-semibold text-gray-900 hover:bg-gray-50"
                  >
                    <%= display_name %>
                  </a>
                <% end %>
              </div>
            </div>
          </div>
        </div>
        <!-- Mobile menu (simplified, hidden by default) -->
        <div class="mobile-menu hidden lg:hidden fixed inset-0 z-50 bg-white">
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
              <button type="button" class="mobile-menu-close -m-2.5 rounded-md p-2.5 text-gray-700">
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
                <summary class="font-semibold text-gray-900 py-2 cursor-pointer">
                  Schulferien 2025
                </summary>
                <div class="ml-4 space-y-1">
                  <%= for {federal_state, display_name} <- federal_states() do %>
                    <a
                      href={"/ferien/d/bundesland/#{federal_state}/2025"}
                      class="block py-1 text-gray-700 hover:text-gray-900"
                    >
                      <%= display_name %>
                    </a>
                  <% end %>
                </div>
              </details>
              <details class="mobile-dropdown">
                <summary class="font-semibold text-gray-900 py-2 cursor-pointer">
                  Schulferien 2026
                </summary>
                <div class="ml-4 space-y-1">
                  <%= for {federal_state, display_name} <- federal_states() do %>
                    <a
                      href={"/ferien/d/bundesland/#{federal_state}/2026"}
                      class="block py-1 text-gray-700 hover:text-gray-900"
                    >
                      <%= display_name %>
                    </a>
                  <% end %>
                </div>
              </details>
              <details class="mobile-dropdown">
                <summary class="font-semibold text-gray-900 py-2 cursor-pointer">
                  Brückentage 2025
                </summary>
                <div class="ml-4 space-y-1">
                  <%= for {federal_state, display_name} <- federal_states() do %>
                    <a
                      href={"/brueckentage/d/bundesland/#{federal_state}/2025"}
                      class="block py-1 text-gray-700 hover:text-gray-900"
                    >
                      <%= display_name %>
                    </a>
                  <% end %>
                </div>
              </details>
              <details class="mobile-dropdown">
                <summary class="font-semibold text-gray-900 py-2 cursor-pointer">
                  Brückentage 2026
                </summary>
                <div class="ml-4 space-y-1">
                  <%= for {federal_state, display_name} <- federal_states() do %>
                    <a
                      href={"/brueckentage/d/bundesland/#{federal_state}/2026"}
                      class="block py-1 text-gray-700 hover:text-gray-900"
                    >
                      <%= display_name %>
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

  # Helper function to get federal states and their display names
  defp federal_states do
    [
      {"baden-wuerttemberg", "Baden-Württemberg"},
      {"bayern", "Bayern"},
      {"berlin", "Berlin"},
      {"brandenburg", "Brandenburg"},
      {"bremen", "Bremen"},
      {"hamburg", "Hamburg"},
      {"hessen", "Hessen"},
      {"mecklenburg-vorpommern", "Mecklenburg-Vorpommern"},
      {"niedersachsen", "Niedersachsen"},
      {"nordrhein-westfalen", "Nordrhein-Westfalen"},
      {"rheinland-pfalz", "Rheinland-Pfalz"},
      {"saarland", "Saarland"},
      {"sachsen", "Sachsen"},
      {"sachsen-anhalt", "Sachsen-Anhalt"},
      {"schleswig-holstein", "Schleswig-Holstein"},
      {"thueringen", "Thüringen"}
    ]
  end
end
