defmodule MehrSchulferienWeb.ICalPanelComponent do
  use Phoenix.Component

  import Phoenix.HTML.Link
  alias MehrSchulferienWeb.Router.Helpers, as: Routes

  attr :conn, :map, required: true
  attr :entity_slug, :string, required: true
  attr :entity_name, :string, required: true
  attr :year, :integer, required: true

  def ical_panel(assigns) do
    ~H"""
    <div class="bg-white p-4 rounded-lg shadow-sm">
      <h2 class="text-xl font-bold text-gray-900 mb-3">Feriendaten im iCal-Format</h2>
      <p class="text-gray-700 mb-3 text-sm">
        Importieren Sie die Schulferiendaten in Ihren Terminkalender:
      </p>
      <ul class="space-y-2 list-disc pl-5 text-sm">
        <li>
          <%= link to: Routes.api_i_cal_path(@conn, :show, @entity_slug, vacation_types: "school", year: @year, calendar_year: true), class: "text-blue-600 hover:text-blue-800 cursor-pointer" do %>
            iCal Schulferien <%= @entity_name %> <%= @year %>
          <% end %>
        </li>
        <li>
          <%= link to: Routes.api_i_cal_path(@conn, :show, @entity_slug, vacation_types: "school", year: @year - 1), class: "text-blue-600 hover:text-blue-800 cursor-pointer" do %>
            iCal Schuljahr <%= @year - 1 %>/<%= @year %> <%= @entity_name %>
          <% end %>
        </li>
        <li>
          <%= link to: Routes.api_i_cal_path(@conn, :show, @entity_slug, vacation_types: "school", year: @year), class: "text-blue-600 hover:text-blue-800 cursor-pointer" do %>
            iCal Schuljahr <%= @year %>/<%= @year + 1 %> <%= @entity_name %>
          <% end %>
        </li>
      </ul>
    </div>
    """
  end
end
