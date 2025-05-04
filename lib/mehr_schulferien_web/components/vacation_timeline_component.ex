defmodule MehrSchulferienWeb.VacationTimelineComponent do
  use Phoenix.Component

  @doc """
  Renders a vacation timeline.

  ## Example
      <.vacation_timeline 
        days_to_show={@days_to_show}
        months={@months}
        all_periods={@all_periods}
        days_count={@days_count}
        months_with_days={@months_with_days}
      />
  """
  attr :days_to_show, :list, required: true
  attr :months, :map, required: true
  attr :all_periods, :list, required: true
  attr :days_count, :integer, required: true
  attr :months_with_days, :list, required: true

  def vacation_timeline(assigns) do
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
                is_vacation -> "bg-green-300"
                is_public_holiday -> "bg-blue-300"
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
      <ul class="list-disc pl-5 text-sm">
        <%= for period <- @all_periods do %>
          <% 
            holiday_type = Map.get(period, :holiday_or_vacation_type, %{})
            is_school_vacation = Map.get(period, :is_school_vacation, false)
            name = Map.get(holiday_type, :name, "")
            # CSS-Klasse basierend auf Art des Ereignisses
            text_class = if is_school_vacation, do: "text-green-800", else: "text-blue-800"
          %>
          <li class={text_class}>
            <%= name %> 
            <%= if Date.compare(period.starts_on, period.ends_on) == :eq do %>
              (<%= Calendar.strftime(period.starts_on, "%d.%m.%Y") %>)
            <% else %>
              (<%= Calendar.strftime(period.starts_on, "%d.%m.%Y") %> - <%= Calendar.strftime(period.ends_on, "%d.%m.%Y") %>)
            <% end %>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end 