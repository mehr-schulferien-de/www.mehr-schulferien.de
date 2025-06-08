defmodule MehrSchulferienWeb.Shared.IcalPanelComponent do
  use Phoenix.Component
  import Phoenix.HTML.Link

  alias MehrSchulferienWeb.Router.Helpers, as: Routes

  attr :conn, :any, required: true
  attr :location, :any, required: true
  attr :year, :integer, required: true

  def ical_panel(assigns) do
    ~H"""
    <div class="bg-white p-4 rounded-lg shadow-sm">
      <div class="flex items-center mb-3">
        <div class="bg-blue-500 p-1.5 rounded-md mr-2">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4 text-white"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
            />
          </svg>
        </div>
        <h2 class="text-lg font-semibold text-gray-900">iCal-Download</h2>
      </div>

      <div class="space-y-1.5">
        <.ical_link
          conn={@conn}
          location={@location}
          year={@year}
          type="calendar_year"
          icon="calendar"
        />
        <.ical_link
          conn={@conn}
          location={@location}
          year={@year}
          type="school_year_previous"
          icon="academic-cap"
        />
        <.ical_link
          conn={@conn}
          location={@location}
          year={@year}
          type="school_year_current"
          icon="academic-cap"
        />
      </div>
    </div>
    """
  end

  attr :conn, :any, required: true
  attr :location, :any, required: true
  attr :year, :integer, required: true
  attr :type, :string, required: true
  attr :icon, :string, default: "calendar"

  defp ical_link(assigns) do
    ~H"""
    <div class="flex items-center py-1.5 px-2 rounded hover:bg-white/60 transition-colors duration-150 group">
      <div class="flex-shrink-0 mr-2">
        <.icon name={@icon} class="h-3.5 w-3.5 text-blue-600" />
      </div>
      <div class="flex-1 min-w-0">
        <%= case @type do %>
          <% "calendar_year" -> %>
            <%= link to: get_ical_path(@conn, @location, @year, true), 
                 class: "text-blue-600 hover:text-blue-800 text-sm font-medium transition-colors duration-150 hover:underline" do %>
              Schulferien <%= @year %>
            <% end %>
          <% "school_year_previous" -> %>
            <%= link to: get_ical_path(@conn, @location, @year - 1, false), 
                 class: "text-blue-600 hover:text-blue-800 text-sm font-medium transition-colors duration-150 hover:underline" do %>
              Schuljahr <%= @year - 1 %>/<%= @year %>
            <% end %>
          <% "school_year_current" -> %>
            <%= link to: get_ical_path(@conn, @location, @year, false), 
                 class: "text-blue-600 hover:text-blue-800 text-sm font-medium transition-colors duration-150 hover:underline" do %>
              Schuljahr <%= @year %>/<%= @year + 1 %>
            <% end %>
        <% end %>
      </div>
      <div class="flex-shrink-0 ml-1 text-gray-400 group-hover:text-blue-500 transition-colors duration-150">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-3.5 w-3.5"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          />
        </svg>
      </div>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :class, :string, default: ""

  defp icon(assigns) do
    ~H"""
    <%= case @name do %>
      <% "calendar" -> %>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class={@class}
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
          />
        </svg>
      <% "academic-cap" -> %>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class={@class}
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
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
        </svg>
      <% _ -> %>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class={@class}
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
          />
        </svg>
    <% end %>
    """
  end

  defp get_ical_path(conn, location, year, calendar_year) do
    slug = get_location_slug(location)

    if calendar_year do
      Routes.api_i_cal_path(conn, :show, slug,
        vacation_types: "school",
        year: year,
        calendar_year: true
      )
    else
      Routes.api_i_cal_path(conn, :show, slug, vacation_types: "school", year: year)
    end
  end

  defp get_location_slug(location) do
    cond do
      Map.has_key?(location, :slug) -> location.slug
      true -> raise "Location must have a slug field"
    end
  end
end
