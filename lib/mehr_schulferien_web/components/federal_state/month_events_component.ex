defmodule MehrSchulferienWeb.FederalState.MonthEventsComponent do
  use Phoenix.Component

  alias MehrSchulferienWeb.ViewHelpers
  alias MehrSchulferienWeb.Formatters.DateFormatter
  import MehrSchulferienWeb.FederalState.PeriodNameComponent

  attr :month_periods, :list, required: true
  attr :month_public_periods, :list, required: true
  attr :all_periods, :list, required: true

  # Helper function for period date formatting
  defp format_period_date(period) do
    if Date.compare(period.starts_on, period.ends_on) == :eq do
      # Single date
      if period.starts_on.year != Date.utc_today().year do
        DateFormatter.format_date_with_short_year(period.starts_on)
      else
        DateFormatter.format_date_short(period.starts_on)
      end
    else
      # Date range
      start_formatted =
        if period.starts_on.year != period.ends_on.year do
          DateFormatter.format_date_with_short_year(period.starts_on)
        else
          DateFormatter.format_date_short(period.starts_on)
        end

      end_formatted =
        if period.starts_on.year != period.ends_on.year do
          DateFormatter.format_date_with_short_year(period.ends_on)
        else
          DateFormatter.format_date_short(period.ends_on)
        end

      "#{start_formatted} - #{end_formatted}"
    end
  end

  def month_events(assigns) do
    ~H"""
    <div class="mt-3 text-xs border-t border-gray-200 pt-2">
      <ul class="space-y-1">
        <%= for period <- @month_public_periods do %>
          <li class="flex justify-between items-start">
            <span class="font-medium text-blue-700 flex-1 pr-2">
              <.period_name period={period} />
            </span>
            <span class="text-gray-600 whitespace-nowrap">
              <%= format_period_date(period) %>
            </span>
          </li>
        <% end %>

        <%= for period <- @month_periods do %>
          <li class="flex justify-between items-start">
            <span class="font-medium text-green-700 flex-1 pr-2">
              <.period_name period={period} />
              <% days = Date.diff(period.ends_on, period.starts_on) + 1 %>
              <% effective_duration = ViewHelpers.calculate_effective_duration(period, @all_periods) %>
              <% difference = effective_duration - days %>
              <span class="font-normal ml-1">
                (<%= days %>
                <%= if difference != 0 do %>
                  <span class="text-gray-500">+ <%= difference %></span>
                <% end %>
                <%= if days == 1, do: "Tag", else: "Tage" %>)
              </span>
              <%= if period.holiday_or_vacation_type.name == "Beweglicher Ferientag" && period.memo && period.memo != "" do %>
                <span class="text-xs text-gray-600 block mt-0.5">
                  <%= period.memo %>
                </span>
              <% end %>
            </span>
            <span class="text-gray-600 whitespace-nowrap">
              <%= format_period_date(period) %>
            </span>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
