defmodule MehrSchulferienWeb.LanguageSwitcherComponent do
  use MehrSchulferienWeb, :live_component

  def mount(socket) do
    {:ok, assign(socket, dropdown_open: false)}
  end

  def render(assigns) do
    ~H"""
    <div class="relative inline-block text-left" id={"language-switcher-#{@id}"}>
      <button
        type="button"
        class="inline-flex items-center px-3 py-2 border border-slate-300 shadow-sm text-sm font-medium rounded-lg text-slate-700 bg-white hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
        phx-click="toggle_dropdown"
        phx-target={@myself}
        aria-expanded={@dropdown_open}
        aria-haspopup="true"
      >
        <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"
          >
          </path>
        </svg>
        <%= language_name(@current_locale) %>
        <svg class="w-4 h-4 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7">
          </path>
        </svg>
      </button>

      <%= if @dropdown_open do %>
        <div
          class="origin-top-right absolute right-0 mt-2 w-56 rounded-lg shadow-lg bg-white ring-1 ring-black ring-opacity-5 focus:outline-none z-50"
          phx-click-away="close_dropdown"
          phx-target={@myself}
        >
          <div class="py-1" role="menu" aria-orientation="vertical">
            <%= for locale <- @available_locales do %>
              <button
                type="button"
                class={[
                  "group flex items-center w-full px-4 py-2 text-sm text-slate-700 hover:bg-slate-100 hover:text-slate-900",
                  @current_locale == locale && "bg-slate-50 text-slate-900 font-medium"
                ]}
                phx-click="change_language"
                phx-value-locale={locale}
                phx-target={@myself}
                role="menuitem"
              >
                <span class="mr-3 text-lg"><%= country_flag(locale) %></span>
                <%= language_name(locale) %>
                <%= if @current_locale == locale do %>
                  <svg class="w-4 h-4 ml-auto text-slate-500" fill="currentColor" viewBox="0 0 20 20">
                    <path
                      fill-rule="evenodd"
                      d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                      clip-rule="evenodd"
                    >
                    </path>
                  </svg>
                <% end %>
              </button>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("toggle_dropdown", _params, socket) do
    {:noreply, assign(socket, dropdown_open: !socket.assigns.dropdown_open)}
  end

  def handle_event("change_language", %{"locale" => locale}, socket) do
    # Send event to parent LiveView to handle locale change
    send(self(), {:change_locale, locale})
    {:noreply, assign(socket, dropdown_open: false)}
  end

  def handle_event("close_dropdown", _params, socket) do
    {:noreply, assign(socket, dropdown_open: false)}
  end

  defp language_name("de"), do: "Deutsch"
  defp language_name("en"), do: "English"
  defp language_name("ru"), do: "Русский"
  defp language_name("ar"), do: "العربية"
  defp language_name("tr"), do: "Türkçe"
  defp language_name("pl"), do: "Polski"
  defp language_name("fr"), do: "Français"
  defp language_name("uk"), do: "Українська"

  defp country_flag("de"), do: "🇩🇪"
  defp country_flag("en"), do: "🇬🇧"
  defp country_flag("ru"), do: "🇷🇺"
  defp country_flag("ar"), do: "🇸🇦"
  defp country_flag("tr"), do: "🇹🇷"
  defp country_flag("pl"), do: "🇵🇱"
  defp country_flag("fr"), do: "🇫🇷"
  defp country_flag("uk"), do: "🇺🇦"
end
