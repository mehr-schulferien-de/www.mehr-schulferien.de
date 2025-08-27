defmodule MehrSchulferienWeb.FederalState.MonthCalendarComponent do
  use Phoenix.Component

  import MehrSchulferienWeb.FederalState.MonthEventsComponent
  alias MehrSchulferienWeb.FederalState.PartialDataComponent

  attr :month, :integer, required: true
  attr :year, :integer, required: true
  attr :periods, :list, required: true
  attr :public_periods, :list, required: true
  attr :all_periods, :list, required: true

  def month_calendar(assigns) do
    month_name =
      case assigns.month do
        1 -> "Januar"
        2 -> "Februar"
        3 -> "März"
        4 -> "April"
        5 -> "Mai"
        6 -> "Juni"
        7 -> "Juli"
        8 -> "August"
        9 -> "September"
        10 -> "Oktober"
        11 -> "November"
        12 -> "Dezember"
      end

    first_day_of_month = Date.new!(assigns.year, assigns.month, 1)
    first_weekday = Date.day_of_week(first_day_of_month)
    days_in_month = Date.days_in_month(first_day_of_month)
    month_id = "#{String.downcase(month_name)}#{assigns.year}"
    last_day_of_month = Date.new!(assigns.year, assigns.month, days_in_month)

    # Use the more accurate function to determine if this month should be crossed out
    should_cross_out =
      PartialDataComponent.should_cross_out_month?(assigns.month, assigns.year, assigns.periods)

    # Filter periods for this specific month and year
    month_periods =
      Enum.filter(assigns.periods, fn period ->
        period_overlaps_with_month_and_year?(period, first_day_of_month, last_day_of_month)
      end)

    month_public_periods =
      Enum.filter(assigns.public_periods, fn period ->
        period_overlaps_with_month_and_year?(period, first_day_of_month, last_day_of_month)
      end)

    assigns =
      assign(assigns,
        month_name: month_name,
        first_day_of_month: first_day_of_month,
        first_weekday: first_weekday,
        days_in_month: days_in_month,
        month_id: month_id,
        month_periods: month_periods,
        month_public_periods: month_public_periods,
        start_day: 1 - (first_weekday - 1),
        should_cross_out: should_cross_out
      )

    ~H"""
    <section class="bg-white dark:bg-gray-800 rounded shadow p-6 h-full" id={@month_id}>
      <div class={["bridge-day-timeline", @should_cross_out && "opacity-40"]}>
        <table class="border-collapse w-full table-fixed">
          <thead>
            <tr>
              <th
                class={[
                  "text-left py-0.5 pl-1 pr-0 font-semibold text-base border border-gray-200 dark:border-gray-700",
                  @should_cross_out &&
                    "bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400",
                  !@should_cross_out && "bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-gray-100"
                ]}
                colspan="7"
              >
                {@month_name} {@year}
                <%= if @should_cross_out do %>
                  <span class="text-xs ml-2 text-gray-500 italic">(noch keine Daten)</span>
                <% end %>
              </th>
            </tr>
            <tr>
              <th class="border border-gray-200 dark:border-gray-700 text-center bg-gray-50 dark:bg-gray-900 text-xs p-0.5 font-medium text-gray-700 dark:text-gray-300">
                Mo
              </th>
              <th class="border border-gray-200 dark:border-gray-700 text-center bg-gray-50 dark:bg-gray-900 text-xs p-0.5 font-medium text-gray-700 dark:text-gray-300">
                Di
              </th>
              <th class="border border-gray-200 dark:border-gray-700 text-center bg-gray-50 dark:bg-gray-900 text-xs p-0.5 font-medium text-gray-700 dark:text-gray-300">
                Mi
              </th>
              <th class="border border-gray-200 dark:border-gray-700 text-center bg-gray-50 dark:bg-gray-900 text-xs p-0.5 font-medium text-gray-700 dark:text-gray-300">
                Do
              </th>
              <th class="border border-gray-200 dark:border-gray-700 text-center bg-gray-50 dark:bg-gray-900 text-xs p-0.5 font-medium text-gray-700 dark:text-gray-300">
                Fr
              </th>
              <th class="border border-gray-200 dark:border-gray-700 text-center bg-gray-50 dark:bg-gray-900 text-xs p-0.5 font-medium text-gray-700 dark:text-gray-300">
                Sa
              </th>
              <th class="border border-gray-200 dark:border-gray-700 text-center bg-gray-50 dark:bg-gray-900 text-xs p-0.5 font-medium text-gray-700 dark:text-gray-300">
                So
              </th>
            </tr>
          </thead>
          <tbody>
            <%= for week <- 0..5 do %>
              <% week_start_day = @start_day + week * 7
              # Check if this row has any valid days
              has_days =
                Enum.any?(1..7, fn weekday ->
                  day = week_start_day + weekday - 1
                  day > 0 and day <= @days_in_month
                end) %>
              <%= if has_days do %>
                <tr>
                  <% # Calculate empty cells at the beginning of the week
                  empty_cells_before =
                    Enum.count(1..7, fn weekday ->
                      day = week_start_day + weekday - 1
                      day < 1
                    end)

                  # Calculate empty cells at the end of the week
                  empty_cells_after =
                    Enum.count(1..7, fn weekday ->
                      day = week_start_day + weekday - 1
                      day > @days_in_month
                    end)

                  # Render empty cell with colspan at the beginning if needed %>
                  <%= if empty_cells_before > 0 do %>
                    <td
                      colspan={empty_cells_before}
                      class="border border-gray-200 dark:border-gray-700"
                    >
                    </td>
                  <% end %>

                  <%= for weekday <- (empty_cells_before + 1)..(7 - empty_cells_after) do %>
                    <% day = week_start_day + weekday - 1 %>
                    <% current_date = Date.new!(@year, @month, day) %>

                    <% is_public_holiday =
                      Enum.any?(@public_periods, fn period ->
                        Date.compare(period.starts_on, current_date) != :gt &&
                          Date.compare(period.ends_on, current_date) != :lt
                      end) %>

                    <% is_vacation =
                      Enum.any?(@periods, fn period ->
                        Date.compare(period.starts_on, current_date) != :gt &&
                          Date.compare(period.ends_on, current_date) != :lt
                      end) %>

                    <% # Get both background and text colors based on day type
                    day_type_classes =
                      cond do
                        is_public_holiday ->
                          day_colors = MehrSchulferienWeb.Shared.DesignTokens.day_type_colors()
                          "#{day_colors.holiday.light_background} #{day_colors.holiday.text}"

                        is_vacation ->
                          day_colors = MehrSchulferienWeb.Shared.DesignTokens.day_type_colors()
                          "#{day_colors.vacation.light_background} #{day_colors.vacation.text}"

                        weekday >= 6 ->
                          day_colors = MehrSchulferienWeb.Shared.DesignTokens.day_type_colors()
                          "#{day_colors.weekend.light_background} #{day_colors.weekend.text}"

                        true ->
                          "text-gray-900 dark:text-gray-100"
                      end %>

                    <td class={[
                      "border border-gray-200 dark:border-gray-700 text-center py-1 w-1/12 text-xs h-[30px] font-medium",
                      day_type_classes
                    ]}>
                      {day}.
                    </td>
                  <% end %>

                  <% # Render empty cell with colspan at the end if needed %>
                  <%= if empty_cells_after > 0 do %>
                    <td
                      colspan={empty_cells_after}
                      class="border border-gray-200 dark:border-gray-700"
                    >
                    </td>
                  <% end %>
                </tr>
              <% end %>
            <% end %>
          </tbody>
        </table>
      </div>

      <%= if length(@month_periods) > 0 || length(@month_public_periods) > 0 do %>
        <.month_events
          month_periods={@month_periods}
          month_public_periods={@month_public_periods}
          all_periods={@all_periods}
        />
      <% end %>
    </section>
    """
  end

  # Helper function to check if a period overlaps with a specific month and year
  defp period_overlaps_with_month_and_year?(period, first_day_of_month, last_day_of_month) do
    # A period overlaps with the month if:
    # 1. It starts before or on the last day of the month AND
    # 2. It ends on or after the first day of the month
    Date.compare(period.starts_on, last_day_of_month) != :gt &&
      Date.compare(period.ends_on, first_day_of_month) != :lt
  end
end
