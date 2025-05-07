defmodule MehrSchulferienWeb.TimelineHeaderComponent do
  use Phoenix.Component

  alias MehrSchulferien.Calendars.DateHelpers

  @doc """
  Renders month and day headers for a timeline.

  ## Example
      <.timeline_header days={@days_to_show} />
  """
  attr :days, :list, required: true, doc: "List of days to show in the timeline"

  def timeline_header(assigns) do
    # Group days by month for header
    month_groups = Enum.group_by(assigns.days, fn day -> {day.year, day.month} end)
    sorted_month_groups = Enum.sort(month_groups)
    months_map = DateHelpers.get_months_map()

    assigns =
      Map.merge(assigns, %{
        sorted_month_groups: sorted_month_groups,
        months_map: months_map
      })

    ~H"""
    <thead>
      <tr>
        <%= for {{year, month}, days} <- @sorted_month_groups do %>
          <th
            class="text-left py-0.5 pl-1 pr-0 font-semibold text-xs border border-gray-200 bg-gray-50"
            colspan={length(days)}
          >
            <%= @months_map[month] %> <%= year %>
          </th>
        <% end %>
      </tr>
      <tr>
        <%= for day <- @days do %>
          <% weekday = Date.day_of_week(day) %>
          <td class="bg-gray-50 text-[11px] p-0.5 font-normal h-5 border border-gray-200 text-center">
            <%= DateHelpers.weekday(weekday, :short) %>
          </td>
        <% end %>
      </tr>
    </thead>
    """
  end
end
