defmodule MehrSchulferienWeb.Shared.MapLinksComponent do
  @moduledoc """
  Shared map links component for displaying links to various map services.
  Replaces duplicated map service links found in city and school templates.
  """
  use Phoenix.Component

  attr :name, :string, required: true
  attr :street, :string, required: true
  attr :zip_code, :string, required: true
  attr :city, :string, required: true
  attr :show_header, :boolean, default: true
  attr :class, :string, default: ""

  def map_links(assigns) do
    map_query =
      URI.encode("#{assigns.name}, #{assigns.street}, #{assigns.zip_code} #{assigns.city}")

    assigns = assign(assigns, :map_query, map_query)

    ~H"""
    <div class={@class}>
      <%= if @show_header do %>
        <h3 class="text-lg font-semibold text-gray-900 mb-3 flex items-center">
          <svg
            class="w-5 h-5 mr-2 text-gray-600"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7"
            />
          </svg>
          Karten
        </h3>
      <% end %>

      <ul class="space-y-1 list-disc pl-6 text-sm">
        <li>
          <a
            href={"https://www.google.com/maps?q=#{@map_query}"}
            target="_blank"
            rel="noopener noreferrer"
            class="text-blue-600 hover:text-blue-800 hover:underline cursor-pointer"
          >
            Google Maps
          </a>
        </li>
        <li>
          <a
            href={"https://www.openstreetmap.org/search?query=#{@map_query}"}
            target="_blank"
            rel="noopener noreferrer"
            class="text-blue-600 hover:text-blue-800 hover:underline cursor-pointer"
          >
            OpenStreetMap
          </a>
        </li>
        <li>
          <a
            href={"https://maps.apple.com/?q=#{@map_query}"}
            target="_blank"
            rel="noopener noreferrer"
            class="text-blue-600 hover:text-blue-800 hover:underline cursor-pointer"
          >
            Apple Maps
          </a>
        </li>
      </ul>
    </div>
    """
  end
end
