defmodule MehrSchulferienWeb.FederalState.PeriodsTableComponent do
  use Phoenix.Component

  import MehrSchulferienWeb.FederalState.Helpers
  import MehrSchulferienWeb.FederalState.PeriodNameComponent
  alias MehrSchulferien.Calendars.DateHelpers

  attr :periods, :list, required: true
  attr :all_periods, :list, required: true

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
              Dauer*
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-200">
          <%= for period <- @periods do %>
            <tr
              class="hover:bg-gray-50 cursor-pointer"
              onclick={"window.location.href='#month-#{period.starts_on.month}'"}
            >
              <td class="px-2 sm:px-4 py-2 sm:py-3 text-sm font-medium text-gray-900">
                <.period_name period={period} />
              </td>
              <td class="px-2 sm:px-4 py-2 sm:py-3 text-sm text-gray-700">
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
              <td class="hidden sm:table-cell px-2 sm:px-4 py-2 sm:py-3 text-sm text-gray-700 whitespace-nowrap">
                <% start_day = Date.day_of_week(period.starts_on)
                end_day = Date.day_of_week(period.ends_on)

                start_day_german = DateHelpers.weekday(start_day, :short_with_dot)
                end_day_german = DateHelpers.weekday(end_day, :short_with_dot) %>
                <%= start_day_german %> - <%= end_day_german %>
              </td>
              <td class="px-2 sm:px-4 py-2 sm:py-3 text-sm text-gray-700">
                <% days = Date.diff(period.ends_on, period.starts_on) + 1 %>
                <% effective_duration = calculate_effective_duration(period, @all_periods) %>
                <% difference = effective_duration - days %>

                <%= days %> <%= if days == 1, do: "Tag", else: "Tage" %>
                <%= if difference != 0 do %>
                  <span class="text-gray-500">(+<%= difference %>)</span>
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
          * Die effektive Dauer (das + in der Klammer) enthält angrenzende Wochenenden oder andere Feiertage, die zusätzlich freie Tage ergeben.
        </div>
      <% end %>
    </div>
    """
  end
end
