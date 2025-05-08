defmodule MehrSchulferienWeb.City.PaginationComponent do
  use Phoenix.Component

  import Phoenix.HTML.Link
  alias MehrSchulferienWeb.Router.Helpers, as: Routes

  attr :conn, :map, required: true
  attr :country, :map, required: true
  attr :federal_state, :map, required: true
  attr :city, :map, required: true
  attr :years_with_data, :list, required: true
  attr :year, :integer, required: true

  def pagination(assigns) do
    ~H"""
    <div class="flex items-center w-full sm:w-auto mt-4 sm:mt-0">
      <%= if length(@years_with_data) > 0 do %>
        <div class="inline-flex rounded-md shadow-sm w-full" role="group">
          <% # Logic for pagination with different max visible years for mobile and desktop
          mobile_max_visible = 3
          current_index = Enum.find_index(@years_with_data, fn y -> y == @year end) || 0
          total_years = length(@years_with_data)

          # Calculate which years to show for mobile
          {mobile_visible_years, _} =
            cond do
              total_years <= mobile_max_visible ->
                # Show all years if total is 3 or less
                {@years_with_data, false}

              current_index <= 0 ->
                # Current year is the first, show first 3
                {Enum.take(@years_with_data, mobile_max_visible), false}

              current_index >= total_years - 1 ->
                # Current year is the last, show last 3
                {Enum.take(@years_with_data, -mobile_max_visible), false}

              true ->
                # Current year is in the middle, show 1 before and 1 after when possible
                start_idx = max(0, current_index - 1)
                end_idx = min(total_years - 1, current_index + 1)

                years = Enum.slice(@years_with_data, start_idx..end_idx)
                {years, false}
            end

          # Determine if prev/next arrows should be enabled
          prev_year = if current_index > 0, do: Enum.at(@years_with_data, current_index - 1)

          next_year =
            if current_index < total_years - 1, do: Enum.at(@years_with_data, current_index + 1) %>

          <% # Mobile pagination (3 years) %>
          <div class="flex w-full">
            <%= if prev_year do %>
              <%= link to: Routes.city_path(@conn, :show_year, @country.slug, @city.slug, prev_year), 
                      class: "px-4 py-2 text-sm font-medium bg-white text-gray-700 border border-gray-200 hover:bg-gray-100 hover:text-blue-700 rounded-l-lg flex items-center" do %>
                <svg
                  class="h-5 w-5"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M15 19l-7-7 7-7"
                  >
                  </path>
                </svg>
              <% end %>
            <% else %>
              <span class="px-4 py-2 text-sm font-medium bg-gray-100 text-gray-400 border border-gray-200 rounded-l-lg cursor-not-allowed flex items-center">
                <svg
                  class="h-5 w-5"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M15 19l-7-7 7-7"
                  >
                  </path>
                </svg>
              </span>
            <% end %>

            <div class="flex flex-grow">
              <%= for year <- mobile_visible_years do %>
                <%= if year == @year do %>
                  <span class="px-4 py-2 text-sm font-medium bg-blue-600 text-white border border-blue-600 flex-1 text-center">
                    <%= year %>
                  </span>
                <% else %>
                  <%= link to: Routes.city_path(@conn, :show_year, @country.slug, @city.slug, year), 
                          class: "px-4 py-2 text-sm font-medium bg-white text-gray-700 border border-gray-200 hover:bg-gray-100 hover:text-blue-700 flex-1 text-center" do %>
                    <%= year %>
                  <% end %>
                <% end %>
              <% end %>
            </div>

            <%= if next_year do %>
              <%= link to: Routes.city_path(@conn, :show_year, @country.slug, @city.slug, next_year), 
                      class: "px-4 py-2 text-sm font-medium bg-white text-gray-700 border border-gray-200 hover:bg-gray-100 hover:text-blue-700 rounded-r-lg flex items-center" do %>
                <svg
                  class="h-5 w-5"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5l7 7-7 7"
                  >
                  </path>
                </svg>
              <% end %>
            <% else %>
              <span class="px-4 py-2 text-sm font-medium bg-gray-100 text-gray-400 border border-gray-200 rounded-r-lg cursor-not-allowed flex items-center">
                <svg
                  class="h-5 w-5"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5l7 7-7 7"
                  >
                  </path>
                </svg>
              </span>
            <% end %>
          </div>
        </div>
      <% else %>
        <span class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg">
          <%= @year %>
        </span>
      <% end %>
    </div>
    """
  end
end
