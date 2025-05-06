defmodule MehrSchulferienWeb.FederalState.MonthEventsComponent do
  use Phoenix.Component

  import MehrSchulferienWeb.FederalState.Helpers
  import MehrSchulferienWeb.FederalState.PeriodNameComponent

  attr :month_periods, :list, required: true
  attr :month_public_periods, :list, required: true
  attr :all_periods, :list, required: true

  def month_events(assigns) do
    ~H"""
    <div class="mt-3 text-xs border-t border-gray-200 pt-2">
      <ul class="space-y-1">
        <%= for period <- @month_public_periods do %>
          <li class="flex justify-between items-start">
            <span class="font-medium text-blue-700 flex-1 pr-2">
              <.period_name period={period} />
            </span>
            <% start_fmt =
              if period.starts_on.year != period.ends_on.year,
                do: "%d.%m.%y",
                else: "%d.%m." %>
            <% end_fmt = start_fmt %>
            <span class="text-gray-600 whitespace-nowrap">
              <%= if Date.compare(period.starts_on, period.ends_on) == :eq do %>
                <%= Calendar.strftime(period.starts_on, start_fmt) %>
              <% else %>
                <%= Calendar.strftime(period.starts_on, start_fmt) %> - <%= Calendar.strftime(
                  period.ends_on,
                  end_fmt
                ) %>
              <% end %>
            </span>
          </li>
        <% end %>

        <%= for period <- @month_periods do %>
          <li class="flex justify-between items-start">
            <span class="font-medium text-green-700 flex-1 pr-2">
              <.period_name period={period} />
              <% days = Date.diff(period.ends_on, period.starts_on) + 1 %>
              <% effective_duration = calculate_effective_duration(period, @all_periods) %>
              <% difference = effective_duration - days %>
              <span class="font-normal ml-1">
                (<%= days %>
                <%= if difference != 0 do %>
                  <span class="text-gray-500">+ <%= difference %></span>
                <% end %>
                <%= if days == 1, do: "Tag", else: "Tage" %>)
              </span>
            </span>
            <% start_fmt =
              if period.starts_on.year != period.ends_on.year,
                do: "%d.%m.%y",
                else: "%d.%m." %>
            <% end_fmt =
              if period.starts_on.year != period.ends_on.year,
                do: "%d.%m.%y",
                else: "%d.%m." %>
            <span class="text-gray-600 whitespace-nowrap">
              <%= if Date.compare(period.starts_on, period.ends_on) == :eq do %>
                <%= Calendar.strftime(period.starts_on, start_fmt) %>
              <% else %>
                <%= Calendar.strftime(period.starts_on, start_fmt) %> - <%= Calendar.strftime(
                  period.ends_on,
                  end_fmt
                ) %>
              <% end %>
            </span>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
