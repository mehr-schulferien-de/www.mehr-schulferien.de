defmodule MehrSchulferienWeb.FederalState.PeriodsTableComponent do
  use Phoenix.Component

  import MehrSchulferienWeb.FederalState.Helpers
  import MehrSchulferienWeb.FederalState.PeriodNameComponent
  alias MehrSchulferien.Calendars.DateHelpers

  attr :periods, :list, required: true
  attr :all_periods, :list, required: true
  attr :today, :any, default: Date.utc_today()

  def periods_table(assigns) do
    ~H"""
    <div class="overflow-x-auto">
      <table class="min-w-full bg-white border border-gray-200">
        <thead>
          <tr>
            <th class="px-2 sm:px-4 py-2 sm:py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider border-b">
              Name
            </th>
            <th class="px-2 sm:px-4 py-2 sm:py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider border-b">
              Termin
            </th>
            <th class="hidden sm:table-cell px-2 sm:px-4 py-2 sm:py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider border-b">
              Wochentage
            </th>
            <th class="px-2 sm:px-4 py-2 sm:py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider border-b">
              Tage*
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-200">
          <%= for period <- @periods do %>
            <% is_current =
              Date.compare(@today, period.starts_on) != :lt &&
                Date.compare(@today, period.ends_on) != :gt %>
            <% is_past =
              Date.compare(@today, period.ends_on) == :gt && period.starts_on.year == @today.year %>
            <% month_name =
              case period.starts_on.month do
                1 -> "januar"
                2 -> "februar"
                3 -> "märz"
                4 -> "april"
                5 -> "mai"
                6 -> "juni"
                7 -> "juli"
                8 -> "august"
                9 -> "september"
                10 -> "oktober"
                11 -> "november"
                12 -> "dezember"
              end %>
            <tr
              class={"hover:bg-gray-50 cursor-pointer #{if is_current, do: "bg-yellow-100"} #{if is_past, do: "text-gray-400"}"}
              onclick={"window.location.href='##{month_name}#{period.starts_on.year}'"}
            >
              <td class="px-2 sm:px-4 py-2 sm:py-3 text-sm font-medium">
                <.period_name period={period} />
              </td>
              <td class="px-2 sm:px-4 py-2 sm:py-3 text-sm">
                <span class="whitespace-nowrap">
                  <span class="sm:hidden">
                    <%= Calendar.strftime(period.starts_on, "%d.%m.") %>
                  </span>
                  <span class="hidden sm:inline">
                    <%= Calendar.strftime(period.starts_on, "%d.%m.%Y") %>
                  </span>
                  -
                  <span class="sm:hidden">
                    <%= Calendar.strftime(period.ends_on, "%d.%m.") %>
                  </span>
                  <span class="hidden sm:inline">
                    <%= Calendar.strftime(period.ends_on, "%d.%m.%Y") %>
                  </span>
                </span>
              </td>
              <td class="hidden sm:table-cell px-2 sm:px-4 py-2 sm:py-3 text-sm whitespace-nowrap">
                <% start_day = Date.day_of_week(period.starts_on)
                end_day = Date.day_of_week(period.ends_on)

                start_day_german = DateHelpers.weekday(start_day, :short_with_dot)
                end_day_german = DateHelpers.weekday(end_day, :short_with_dot) %>
                <%= start_day_german %> - <%= end_day_german %>
              </td>
              <td class="px-2 sm:px-4 py-2 sm:py-3 text-sm">
                <% days = Date.diff(period.ends_on, period.starts_on) + 1 %>
                <% effective_duration = calculate_effective_duration(period, @all_periods) %>
                <% difference = effective_duration - days %>

                <%= days %>
                <%= if difference != 0 do %>
                  / <%= days + difference %>
                <% end %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>

      <% has_differences =
        Enum.any?(@periods, fn period ->
          days = Date.diff(period.ends_on, period.starts_on) + 1
          effective_duration = calculate_effective_duration(period, @all_periods)
          effective_duration != days
        end) %>

      <%= if has_differences do %>
        <div class="text-xs text-gray-500 mt-2">
          * Die effektive Dauer (der zweite Wert) enthält angrenzende Wochenenden oder andere Feiertage, die zusätzlich freie Tage ergeben.
        </div>
      <% end %>
    </div>
    """
  end
end
