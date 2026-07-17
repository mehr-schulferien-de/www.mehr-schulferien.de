defmodule MehrSchulferienWeb.VacationPlanner.VacationPlannerCalendarComponent do
  @moduledoc """
  Calendar component for the vacation planner that displays month grids
  with color-coded days showing vacation days vs. free days (weekends/holidays).
  """
  use Phoenix.Component

  alias MehrSchulferienWeb.Shared.DesignTokens

  attr :result, :map, required: true
  attr :public_periods, :list, required: true
  attr :vacation_dates, :list, required: true
  attr :school_vacation_periods, :list, default: []

  @doc """
  Renders a calendar grid showing the vacation period with color-coded days.

  - Orange/Yellow: Vacation days (user must take off work)
  - Orange/Yellow with stripes: Vacation days during school vacations (more expensive)
  - Blue: Public holidays (free)
  - Gray: Weekend days (free)
  - White: Regular workdays outside the period
  """
  def vacation_planner_calendar(assigns) do
    # Determine which months to display based on the result's date range
    months = get_relevant_months(assigns.result.start_date, assigns.result.end_date)

    # Convert vacation_dates list to a MapSet for O(1) lookups
    vacation_dates_set = MapSet.new(assigns.vacation_dates)

    assigns =
      assign(assigns,
        months: months,
        vacation_dates_set: vacation_dates_set
      )

    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <%= for {year, month} <- @months do %>
        <.month_calendar
          year={year}
          month={month}
          result={@result}
          public_periods={@public_periods}
          vacation_dates_set={@vacation_dates_set}
          school_vacation_periods={@school_vacation_periods}
        />
      <% end %>
    </div>
    """
  end

  attr :year, :integer, required: true
  attr :month, :integer, required: true
  attr :result, :map, required: true
  attr :public_periods, :list, required: true
  attr :vacation_dates_set, :any, required: true
  attr :school_vacation_periods, :list, default: []

  defp month_calendar(assigns) do
    month_name = get_month_name(assigns.month)
    first_day_of_month = Date.new!(assigns.year, assigns.month, 1)
    first_weekday = Date.day_of_week(first_day_of_month)
    days_in_month = Date.days_in_month(first_day_of_month)

    assigns =
      assign(assigns,
        month_name: month_name,
        first_weekday: first_weekday,
        days_in_month: days_in_month,
        start_day: 1 - (first_weekday - 1)
      )

    ~H"""
    <section class="bg-white dark:bg-gray-800 rounded shadow p-4">
      <table class="border-collapse w-full table-fixed">
        <thead>
          <tr>
            <th
              class="text-left py-0.5 pl-1 pr-0 font-semibold text-base border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-gray-100"
              colspan="7"
            >
              {@month_name} {@year}
            </th>
          </tr>
          <tr>
            <th class="border border-gray-200 dark:border-gray-700 text-center bg-gray-50 dark:bg-gray-900 text-xs p-0.5 font-medium text-gray-900 dark:text-gray-100">
              Mo
            </th>
            <th class="border border-gray-200 dark:border-gray-700 text-center bg-gray-50 dark:bg-gray-900 text-xs p-0.5 font-medium text-gray-900 dark:text-gray-100">
              Di
            </th>
            <th class="border border-gray-200 dark:border-gray-700 text-center bg-gray-50 dark:bg-gray-900 text-xs p-0.5 font-medium text-gray-900 dark:text-gray-100">
              Mi
            </th>
            <th class="border border-gray-200 dark:border-gray-700 text-center bg-gray-50 dark:bg-gray-900 text-xs p-0.5 font-medium text-gray-900 dark:text-gray-100">
              Do
            </th>
            <th class="border border-gray-200 dark:border-gray-700 text-center bg-gray-50 dark:bg-gray-900 text-xs p-0.5 font-medium text-gray-900 dark:text-gray-100">
              Fr
            </th>
            <th class="border border-gray-200 dark:border-gray-700 text-center bg-gray-50 dark:bg-gray-900 text-xs p-0.5 font-medium text-gray-900 dark:text-gray-100">
              Sa
            </th>
            <th class="border border-gray-200 dark:border-gray-700 text-center bg-gray-50 dark:bg-gray-900 text-xs p-0.5 font-medium text-gray-900 dark:text-gray-100">
              So
            </th>
          </tr>
        </thead>
        <tbody>
          <%= for week <- 0..5 do %>
            <% week_start_day = @start_day + week * 7

            has_days =
              Enum.any?(1..7, fn weekday ->
                day = week_start_day + weekday - 1
                day > 0 and day <= @days_in_month
              end) %>
            <%= if has_days do %>
              <tr>
                <% empty_cells_before =
                  Enum.count(1..7, fn weekday ->
                    day = week_start_day + weekday - 1
                    day < 1
                  end)

                empty_cells_after =
                  Enum.count(1..7, fn weekday ->
                    day = week_start_day + weekday - 1
                    day > @days_in_month
                  end) %>

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
                  <% day_type_classes =
                    get_day_classes(
                      current_date,
                      weekday,
                      @result,
                      @public_periods,
                      @vacation_dates_set,
                      @school_vacation_periods
                    ) %>

                  <td class={[
                    "border border-gray-200 dark:border-gray-700 text-center py-1 w-1/12 text-xs h-[30px] font-medium",
                    day_type_classes
                  ]}>
                    {day}.
                  </td>
                <% end %>

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
    </section>
    """
  end

  # Determine which months to display based on the date range
  defp get_relevant_months(start_date, end_date) do
    start_month = {start_date.year, start_date.month}
    end_month = {end_date.year, end_date.month}

    # Generate all months from start to end
    generate_months(start_month, end_month, [])
    |> Enum.reverse()
  end

  defp generate_months({year, month} = current, end_month, acc) do
    if current > end_month do
      acc
    else
      next =
        if month == 12 do
          {year + 1, 1}
        else
          {year, month + 1}
        end

      generate_months(next, end_month, [current | acc])
    end
  end

  # Get CSS classes for a day based on its type
  defp get_day_classes(
         date,
         _weekday,
         _result,
         public_periods,
         vacation_dates_set,
         school_vacation_periods
       ) do
    day_colors = DesignTokens.day_type_colors()

    # Use actual day of week from the date (6 = Saturday, 7 = Sunday in Elixir)
    day_of_week = Date.day_of_week(date)
    is_weekend = day_of_week in [6, 7]

    cond do
      # Vacation day during school vacation - yellow with diagonal stripes
      MapSet.member?(vacation_dates_set, date) and
          is_school_vacation?(date, school_vacation_periods) ->
        "#{day_colors.bridge_day.light_background} #{day_colors.bridge_day.text} vacation-in-school-vacation"

      # Vacation day (user must take off) - use orange/yellow color
      MapSet.member?(vacation_dates_set, date) ->
        "#{day_colors.bridge_day.light_background} #{day_colors.bridge_day.text}"

      # Public holiday (even on weekends) - use blue color
      is_public_holiday?(date, public_periods) ->
        "#{day_colors.holiday.light_background} #{day_colors.holiday.text}"

      # School vacation (not a user vacation day) - use green color
      is_school_vacation?(date, school_vacation_periods) ->
        "#{day_colors.vacation.light_background} #{day_colors.vacation.text}"

      # Weekend (Saturday/Sunday) - use design tokens for consistent styling
      is_weekend ->
        "#{day_colors.weekend.light_background} #{day_colors.weekend.text}"

      # Regular workday
      true ->
        "text-gray-900 dark:text-gray-100"
    end
  end

  defp is_public_holiday?(date, public_periods) do
    Enum.any?(public_periods, fn period ->
      Date.compare(period.starts_on, date) != :gt and
        Date.compare(period.ends_on, date) != :lt
    end)
  end

  defp is_school_vacation?(date, school_vacation_periods) do
    Enum.any?(school_vacation_periods, fn period ->
      Date.compare(period.starts_on, date) != :gt and
        Date.compare(period.ends_on, date) != :lt
    end)
  end

  defp get_month_name(month) do
    MehrSchulferien.Calendars.DateHelpers.get_months_map()[month]
  end
end
