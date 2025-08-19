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
        <%= for {{school_year, periods}, index} <- Enum.with_index(@grouped_periods) do %>
          <div class={"mb-4 sm:mb-6 #{if index > 0, do: "mt-6 sm:mt-8 pt-4 sm:pt-6 border-t border-gray-300 dark:border-gray-600"}"}>
            <div class="flex items-center gap-2 sm:gap-3 mb-2 sm:mb-3">
              <h3 class="text-base sm:text-lg font-semibold text-gray-800 dark:text-gray-200">
                Schuljahr {school_year}/{school_year + 1}
              </h3>
              <%= if school_year == @current_school_year do %>
                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] sm:text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                  Aktuell
                </span>
              <% else %>
                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] sm:text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">
                  Kommend
                </span>
              <% end %>
            </div>

            <table class="min-w-full bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 table-fixed rounded-lg overflow-hidden">
              <colgroup>
                <col class="w-1/2 sm:w-1/2" />
                <col class="w-5/12 sm:w-1/3" />
                <col class="w-1/12 sm:w-1/6" />
              </colgroup>
              <thead>
                <tr class={
                  if school_year != @current_school_year,
                    do: "bg-blue-50 dark:bg-blue-950",
                    else: "bg-gray-50 dark:bg-gray-900"
                }>
                  <th class="px-2 sm:px-4 py-1.5 sm:py-3 text-left text-[10px] sm:text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider border-b dark:border-gray-600">
                    Name
                  </th>
                  <th class="px-2 sm:px-4 py-1.5 sm:py-3 text-left text-[10px] sm:text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider border-b dark:border-gray-600">
                    Termin
                  </th>
                  <th class="px-2 sm:px-4 py-1.5 sm:py-3 text-left text-[10px] sm:text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider border-b dark:border-gray-600">
                    Tage
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
                    show_year_in_dates={true}
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
