defmodule MehrSchulferienWeb.VacationTimelineComponent do
  use Phoenix.Component

  @doc """
  Renders a vacation timeline.

  ## Example
      <%= VacationTimelineComponent.render(
        days_to_show: @days_to_show,
        months: @months,
        all_periods: @all_periods,
        days_count: @days_count,
        months_with_days: @months_with_days
      ) %>
  """
  def render(opts) when is_list(opts) do
    # Convert keyword list to map
    render(Map.new(opts))
  end
  
  def render(assigns) when is_map(assigns) do
    # Get the first and last day from the timeline
    first_day = List.first(assigns[:days_to_show])
    last_day = List.last(assigns[:days_to_show])
    
    # Only check years from periods that are actually visible in the timeline
    visible_periods = Enum.filter(assigns[:all_periods], fn period ->
      Date.compare(period.ends_on, first_day) != :lt && 
      Date.compare(period.starts_on, last_day) != :gt
    end)
    
    # Extract unique years only from visible periods
    years = visible_periods
    |> Enum.map(& &1.starts_on.year)
    |> Enum.concat(Enum.map(visible_periods, & &1.ends_on.year))
    |> Enum.uniq()
    
    has_multiple_years = length(years) > 1
    
    assigns = Map.put(assigns, :has_multiple_years, has_multiple_years)
    
    render_timeline(assigns)
  end

  defp render_timeline(assigns) do
    ~H"""
    <table class="table-fixed border border-gray-300 text-center text-xs" role="presentation">
      <thead>
        <tr>
          <%= for {month_name, days_count, _year, _month} <- @months_with_days do %>
            <td colspan={days_count} class="border border-gray-200 whitespace-nowrap font-semibold text-left pl-1"><%= month_name %></td>
          <% end %>
        </tr>
      </thead>

      <tbody>
        <!-- Tageszeile -->
        <tr>
          <%= for day <- @days_to_show do %>
            <% 
              is_weekend = Date.day_of_week(day) > 5  # 6 = Samstag, 7 = Sonntag
              # Prüfen ob Ferien oder Feiertag
              is_vacation = Enum.any?(@all_periods, fn period -> 
                Map.get(period, :is_school_vacation, false) &&
                Date.compare(day, period.starts_on) != :lt && 
                Date.compare(day, period.ends_on) != :gt 
              end)
              is_public_holiday = Enum.any?(@all_periods, fn period -> 
                Map.get(period, :is_public_holiday, false) &&
                Date.compare(day, period.starts_on) != :lt && 
                Date.compare(day, period.ends_on) != :gt 
              end)
              
              # Klassen für Hintergrundfarbe
              bg_class = cond do
                is_vacation -> "bg-green-600"
                is_public_holiday -> "bg-blue-600"
                is_weekend -> "bg-gray-100"
                true -> ""
              end
            %>
            <td class={"w-6 h-5 border-t border-b border-gray-200 #{bg_class}"}></td>
          <% end %>
        </tr>
      </tbody>
    </table>

    <div class="mt-4">
      <p class="text-sm font-medium mb-2">Ferien und Feiertage im angezeigten Zeitraum:</p>
      <ul class="text-sm">
        <%= for period <- @all_periods do %>
          <% 
            holiday_type = Map.get(period, :holiday_or_vacation_type, %{})
            is_school_vacation = Map.get(period, :is_school_vacation, false)
            name = Map.get(holiday_type, :name, "")
            # CSS-Klasse basierend auf Art des Ereignisses
            marker_color = if is_school_vacation, do: "bg-green-600", else: "bg-blue-600"
          %>
          <li class={"flex items-center space-x-2 mb-1"}>
            <div class={marker_color <> " w-3 h-3 rounded-sm flex-shrink-0"}></div>
            <span>
              <%= name %> 
              <%= if Date.compare(period.starts_on, period.ends_on) == :eq do %>
                <%= if @has_multiple_years do %>
                  (<%= Calendar.strftime(period.starts_on, "%d.%m.%Y") %>)
                <% else %>
                  (<%= Calendar.strftime(period.starts_on, "%d.%m.") %>)
                <% end %>
              <% else %>
                <%= if @has_multiple_years do %>
                  (<%= Calendar.strftime(period.starts_on, "%d.%m.%Y") %> - <%= Calendar.strftime(period.ends_on, "%d.%m.%Y") %>)
                <% else %>
                  (<%= Calendar.strftime(period.starts_on, "%d.%m.") %> - <%= Calendar.strftime(period.ends_on, "%d.%m.") %>)
                <% end %>
              <% end %>
            </span>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end 