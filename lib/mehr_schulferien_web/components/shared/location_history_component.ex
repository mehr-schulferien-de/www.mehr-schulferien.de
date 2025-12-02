defmodule MehrSchulferienWeb.Shared.LocationHistoryComponent do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  @doc """
  Renders the location history section.

  ## Attributes
    * `:recent_locations` - List of recent location maps with type, name, slug, etc.
    * `:show` - Boolean to control visibility (default: true)
  """
  attr :recent_locations, :list, required: true
  attr :show, :boolean, default: true

  def location_history(assigns) do
    ~H"""
    <%= if @show and length(@recent_locations) > 0 do %>
      <div class="mt-6 pt-5 border-t border-gray-200 dark:border-gray-700">
        <div class="flex flex-col gap-3">
          <div class="text-xs font-medium text-gray-600 dark:text-gray-400 uppercase tracking-wider">
            Zuletzt besucht
          </div>
          <!-- Mobile: horizontal flex, Desktop: grid -->
          <% mobile_locations = Enum.take(@recent_locations, 2) %>
          <% show_full_info = true %>
          <div class="flex md:grid md:grid-cols-3 gap-2 md:gap-3">
            <%= for location <- @recent_locations do %>
              <% show_on_mobile = location in mobile_locations %>
              <a
                href={get_location_url(location)}
                class={"group #{if show_on_mobile, do: "flex", else: "hidden md:flex"} #{if show_full_info, do: "flex-row items-center", else: "md:flex-row flex-col items-center md:items-center"} gap-1 md:gap-3 p-2 md:p-3 bg-gray-50 dark:bg-gray-700 hover:bg-gray-100 dark:hover:bg-gray-600 rounded-lg transition-colors flex-1 md:flex-initial"}
              >
                <div class="hidden md:block flex-shrink-0">
                  <%= case location.type do %>
                    <% :federal_state -> %>
                      <div class="w-8 h-8 md:w-10 md:h-10 bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded-lg flex items-center justify-center">
                        <svg
                          class="w-4 h-4 md:w-5 md:h-5"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M3 21v-4m0 0V5a2 2 0 012-2h6.5l1 1H21l-3 6 3 6h-8.5l-1-1H5a2 2 0 00-2 2zm9-13.5V9"
                          />
                        </svg>
                      </div>
                    <% :city -> %>
                      <div class="w-8 h-8 md:w-10 md:h-10 bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400 rounded-lg flex items-center justify-center">
                        <svg
                          class="w-4 h-4 md:w-5 md:h-5"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
                          />
                        </svg>
                      </div>
                    <% :school -> %>
                      <div class="w-8 h-8 md:w-10 md:h-10 bg-purple-100 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400 rounded-lg flex items-center justify-center">
                        <svg
                          class="w-4 h-4 md:w-5 md:h-5"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M12 14l9-5-9-5-9 5 9 5z"
                          />
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z"
                          />
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M12 14l9-5-9-5-9 5 9 5zm0 0l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14zm-4 6v-7.5l4-2.222"
                          />
                        </svg>
                      </div>
                  <% end %>
                </div>
                <div class={"flex-1 min-w-0 #{if show_full_info, do: "text-left", else: "text-center md:text-left"}"}>
                  <div class={"#{if show_full_info, do: "text-sm", else: "text-xs md:text-sm"} font-medium text-gray-900 dark:text-gray-100 group-hover:text-blue-600 dark:group-hover:text-blue-400 #{if show_full_info, do: "", else: "truncate max-w-[80px] md:max-w-none"}"}>
                    <span class="md:hidden">
                      {truncate_name(location.name, location.type, 15)}
                    </span>
                    <span class="hidden md:inline">
                      {truncate_name(location.name, location.type, 23)}
                    </span>
                  </div>
                  <div class={"#{if show_full_info, do: "block", else: "hidden md:block"} text-xs text-gray-600 dark:text-gray-300"}>
                    <%= case location.type do %>
                      <% :federal_state -> %>
                        Bundesland
                      <% :city -> %>
                        Stadt
                      <% :school -> %>
                        {location.city_name}
                    <% end %>
                  </div>
                </div>
                <svg
                  class="hidden md:block w-4 h-4 text-gray-400 dark:text-gray-500 group-hover:text-gray-600 dark:group-hover:text-gray-400 flex-shrink-0"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5l7 7-7 7"
                  />
                </svg>
              </a>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  defp get_location_url(location) do
    case location.type do
      :federal_state -> ~p"/ferien/d/bundesland/#{location.slug}"
      :city -> ~p"/ferien/d/stadt/#{location.slug}"
      :school -> ~p"/ferien/d/schule/#{location.slug}"
    end
  end

  defp truncate_name(name, _type, max_length) do
    if String.length(name) > max_length do
      String.slice(name, 0, max_length) <> "..."
    else
      name
    end
  end
end
