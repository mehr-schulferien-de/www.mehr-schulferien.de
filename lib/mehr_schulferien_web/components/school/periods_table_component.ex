defmodule MehrSchulferienWeb.School.PeriodsTableComponent do
  use Phoenix.Component

  import MehrSchulferienWeb.Shared.PeriodsTableBaseComponent

  attr :periods, :list, required: true
  attr :all_periods, :list, required: true
  attr :today, :any, default: Date.utc_today()
  attr :current_school_year, :integer, required: true
  attr :next_school_year, :integer, required: true

  def periods_table(assigns) do
    # Filter to only show periods from current calendar year and future years,
    # then group by school year and filter to only current and next school year
    current_calendar_year = assigns.today.year

    grouped_periods =
      assigns.periods
      |> Enum.filter(fn period ->
        # Only show periods that start in the current calendar year or later
        period.starts_on.year >= current_calendar_year
      end)
      |> Enum.group_by(fn period ->
        get_school_year(period.starts_on)
      end)
      |> Enum.filter(fn {year, _} ->
        year == assigns.current_school_year || year == assigns.next_school_year
      end)
      |> Enum.sort_by(fn {year, _} -> year end, :asc)

    assigns = assign(assigns, :grouped_periods, grouped_periods)

    ~H"""
    <div>
      <div class="overflow-x-auto">
        <%= for {school_year, periods} <- @grouped_periods do %>
          <div class="mb-6">
            <h3 class="text-lg font-semibold text-gray-800 dark:text-gray-200 mb-2">
              Schuljahr {school_year}/{school_year + 1}
            </h3>

            <table class="min-w-full bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 table-fixed">
              <colgroup>
                <col class="w-1/2" />
                <col class="w-1/3" />
                <col class="w-1/6" />
              </colgroup>
              <thead>
                <tr>
                  <th class="px-2 sm:px-4 py-2 sm:py-3 bg-gray-50 dark:bg-gray-900 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider border-b dark:border-gray-600">
                    Name
                  </th>
                  <th class="px-2 sm:px-4 py-2 sm:py-3 bg-gray-50 dark:bg-gray-900 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider border-b dark:border-gray-600">
                    Termin
                  </th>
                  <th class="px-2 sm:px-4 py-2 sm:py-3 bg-gray-50 dark:bg-gray-900 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider border-b dark:border-gray-600">
                    Tage*
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
                <%= for period <- Enum.sort_by(periods, & &1.starts_on, Date) do %>
                  <.period_row
                    period={period}
                    all_periods={@all_periods}
                    today={@today}
                    current_year={@current_school_year}
                    show_mobile_dates={true}
                    show_memo={true}
                  />
                <% end %>
              </tbody>
            </table>
          </div>
        <% end %>

        <.periods_footnote periods={@periods} all_periods={@all_periods} />
      </div>
    </div>
    """
  end

  # Helper function to determine school year
  # A school year starts on August 1st
  defp get_school_year(date) do
    if date.month >= 8 do
      date.year
    else
      date.year - 1
    end
  end
end
