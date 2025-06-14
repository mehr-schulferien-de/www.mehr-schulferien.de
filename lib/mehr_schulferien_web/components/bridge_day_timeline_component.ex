defmodule MehrSchulferienWeb.BridgeDayTimelineComponent do
  use Phoenix.Component

  alias MehrSchulferien.Calendars.DateHelpers
  import Phoenix.HTML, only: [raw: 1]

  @doc """
  Renders a bridge day timeline with days and related periods.

  ## Example
      <%= BridgeDayTimelineComponent.bridge_day_timeline(%{
        bridge_day: bridge_day,
        periods: periods,
        reference_date: reference_date,
        vacation_days: vacation_days,
        total_free_days: total_free_days,
        efficiency_percentage: efficiency_percentage
      }) %>
  """
  def bridge_day_timeline(assigns) do
    # Create days list centered around bridge day
    start_date = Date.add(assigns.bridge_day.starts_on, -Map.get(assigns, :window_size, 5))

    days_count =
      Map.get(assigns, :window_size, 5) * 2 +
        Date.diff(assigns.bridge_day.ends_on, assigns.bridge_day.starts_on) + 1

    days_to_show = DateHelpers.create_days(start_date, days_count)

    # Create a bridge period to highlight in the timeline
    bridge_period = %{
      starts_on: assigns.bridge_day.starts_on,
      ends_on: assigns.bridge_day.ends_on,
      is_school_vacation: true,
      holiday_or_vacation_type: %{
        name:
          if(Map.get(assigns, :is_super_bridge_day, false),
            do: "Superbrückentag",
            else:
              if(Date.diff(assigns.bridge_day.ends_on, assigns.bridge_day.starts_on) > 0,
                do: "Super-Brückentage",
                else: "Brückentag"
              )
          )
      }
    }

    # Add bridge period to the timeline periods if it's not already included
    timeline_periods = [bridge_period | Map.get(assigns, :periods, [])]

    # Calculate days until bridge day
    days_until = Date.diff(assigns.bridge_day.starts_on, assigns.reference_date)

    is_future_reference =
      Date.compare(assigns.reference_date, assigns.bridge_day.starts_on) == :gt

    # Create legend items
    legend_items = create_legend_items(bridge_period, Map.get(assigns, :periods, []))

    assigns =
      Map.merge(assigns, %{
        days_to_show: days_to_show,
        days_until: days_until,
        is_future_reference: is_future_reference,
        timeline_periods: timeline_periods,
        legend_items: legend_items
      })

    title = Map.get(assigns, :title)
    is_super_bridge_day = Map.get(assigns, :is_super_bridge_day, false)

    # Determine cell background color
    html = """
    <div class="bridge-day-timeline">
      #{if title do
      "<div class=\"text-sm text-gray-600 mt-2 mb-3\">#{title}</div>"
    else
      ""
    end}
      
      <table class="border-collapse w-full table-fixed">
        #{render_timeline_header(assigns.days_to_show)}
        <tbody>
          <tr>
            #{Enum.map(assigns.days_to_show, fn day ->
      is_weekend = Date.day_of_week(day) > 5
      highest_priority_period = find_period_for_day(assigns.timeline_periods, day)
      cell_bg_class = cond do
        highest_priority_period && Map.get(highest_priority_period, :is_school_vacation, false) -> "bg-purple-600 text-white"
        highest_priority_period && Map.get(highest_priority_period, :is_public_holiday, false) -> "bg-blue-600 text-white"
        is_weekend -> "bg-gray-100"
        true -> ""
      end

      "<td class=\"border border-gray-200 text-center py-1 w-1/12 text-xs h-[30px] #{cell_bg_class}\">#{day.day}.</td>"
    end) |> Enum.join("")}
          </tr>
        </tbody>
      </table>
      
      #{if !is_super_bridge_day do
      """
      <p class="text-sm text-gray-600 mt-2 mb-3">
        #{if !assigns.is_future_reference && assigns.days_until > 0 do
        bridge_day_term = if Date.diff(assigns.bridge_day.ends_on, assigns.bridge_day.starts_on) > 0, do: "nächsten Super-Brückentagen", else: "nächsten Brückentag"
        "Noch #{assigns.days_until} Tage bis zum #{bridge_day_term}."
      else
        if assigns.days_until == 0 do
          bridge_day_term = if Date.diff(assigns.bridge_day.ends_on, assigns.bridge_day.starts_on) > 0, do: "Super-Brückentage sind", else: "Brückentag ist"
          "#{bridge_day_term} heute."
        else
          if assigns.is_future_reference do
            bridge_day_term = if Date.diff(assigns.bridge_day.ends_on, assigns.bridge_day.starts_on) > 0, do: "Diese Super-Brückentage gab es", else: "Diesen Brückentag gab es"
            "#{bridge_day_term} am #{Calendar.strftime(assigns.bridge_day.starts_on, "%d.%m.%Y")}."
          else
            bridge_day_term = if Date.diff(assigns.bridge_day.ends_on, assigns.bridge_day.starts_on) > 0, do: "Super-Brückentage sind", else: "Brückentag ist"
            "#{bridge_day_term} schon vorbei."
          end
        end
      end}
      </p>
      """
    else
      ""
    end}
      
      #{render_legend(assigns.legend_items)}
      
      <p class="text-sm text-gray-800 mt-3">
        #{assigns.vacation_days} #{if assigns.vacation_days == 1, do: "eingereichten Urlaubstag", else: "eingereichte Urlaubstage"} = 
        <span class="font-medium">#{assigns.total_free_days} freie Tage #{if is_super_bridge_day, do: "🎉", else: ""}</span>
        #{if !is_super_bridge_day do
      "(#{assigns.efficiency_percentage}% Gewinn)"
    else
      ""
    end}
      </p>
    </div>
    """

    # Mark the HTML as safe
    raw(html)
  end

  # Render timeline header separately
  defp render_timeline_header(days) do
    # Group days by month for header
    month_groups = Enum.group_by(days, fn day -> {day.year, day.month} end)
    sorted_month_groups = Enum.sort(month_groups)
    months_map = DateHelpers.get_months_map()

    # Determine if we have multiple months
    has_multiple_months = length(sorted_month_groups) > 1

    # Check if we have multiple years
    years = sorted_month_groups |> Enum.map(fn {{year, _month}, _days} -> year end) |> Enum.uniq()
    has_multiple_years = length(years) > 1

    month_headers =
      sorted_month_groups
      |> Enum.with_index()
      |> Enum.map(fn {{{year, month}, month_days}, index} ->
        # Only abbreviate months that show 3 or fewer days
        use_abbreviation =
          has_multiple_months &&
            index < length(sorted_month_groups) - 1 &&
            length(month_days) <= 3

        month_name =
          if use_abbreviation do
            # For months with 3 or fewer days, use abbreviated format
            String.at(months_map[month], 0) <> "."
          else
            # Otherwise use full month name
            months_map[month]
          end

        # Only show the year when there are multiple years and at year changes
        show_year =
          has_multiple_years &&
            (index == 0 ||
               index == length(sorted_month_groups) - 1 ||
               elem(Enum.at(sorted_month_groups, index), 0) |> elem(0) !=
                 elem(Enum.at(sorted_month_groups, index - 1), 0) |> elem(0))

        """
        <th class="text-left py-0.5 pl-1 pr-0 font-semibold text-xs border border-gray-200 bg-gray-50" colspan="#{length(month_days)}">
          #{month_name}#{if show_year, do: " #{year}", else: ""}
        </th>
        """
      end)
      |> Enum.join("")

    weekday_headers =
      Enum.map(days, fn day ->
        weekday = Date.day_of_week(day)
        weekday_abbr = DateHelpers.weekday(weekday, :short)

        """
        <td class="bg-gray-50 text-[11px] p-0.5 font-normal h-5 border border-gray-200 text-center w-1/12">#{weekday_abbr}</td>
        """
      end)
      |> Enum.join("")

    """
    <thead>
      <tr>
        #{month_headers}
      </tr>
      <tr>
        #{weekday_headers}
      </tr>
    </thead>
    """
  end

  # Render legend separately
  defp render_legend(items) do
    legend_items =
      Enum.map(items, fn item ->
        """
        <li class="flex items-center space-x-3">
          <div class="#{item.color} w-4 h-4 flex-shrink-0"></div>
          <span>#{item.label}</span>
        </li>
        """
      end)
      |> Enum.join("")

    """
    <ul class="text-sm space-y-1 mt-4">
      #{legend_items}
    </ul>
    """
  end

  # Find the period that contains the given day
  defp find_period_for_day(periods, day) do
    Enum.find(periods, fn period ->
      Date.compare(day, period.starts_on) != :lt &&
        Date.compare(day, period.ends_on) != :gt
    end)
  end

  # Create legend items from periods
  defp create_legend_items(bridge_period, periods) do
    # First add the bridge day
    bridge_label =
      "#{bridge_period.holiday_or_vacation_type.name} (#{format_date_range(bridge_period)})"

    legend_items = [%{color: "bg-purple-600", label: bridge_label}]

    # Add other periods (holidays)
    holiday_items =
      periods
      |> Enum.filter(fn period ->
        # Don't include regular bridge days with same date range as our main bridge period
        # or any other period that's not a holiday
        period != bridge_period &&
          !date_ranges_overlap?(period, bridge_period) &&
          (Map.get(period, :is_public_holiday, false) ||
             (Map.has_key?(period, :holiday_or_vacation_type) &&
                period.holiday_or_vacation_type.name != "Wochenende"))
      end)
      |> Enum.map(fn period ->
        holiday_name = period.holiday_or_vacation_type.name
        label = "#{holiday_name} (#{format_date_range(period)})"
        %{color: "bg-blue-600", label: label}
      end)

    legend_items ++ holiday_items
  end

  # Helper function to check if two periods overlap
  defp date_ranges_overlap?(period1, period2) do
    # Check if both have same start and end dates, or if they overlap significantly
    (Date.compare(period1.starts_on, period2.starts_on) == :eq &&
       Date.compare(period1.ends_on, period2.ends_on) == :eq) ||
      ((period1.holiday_or_vacation_type.name == "Brückentag" ||
          period1.holiday_or_vacation_type.name == "Brückentage" ||
          period1.holiday_or_vacation_type.name == "Super-Brückentage") &&
         period2.holiday_or_vacation_type.name == "Superbrückentag" &&
         Date.compare(period1.starts_on, period2.starts_on) == :eq)
  end

  # Format a date or date range for display
  defp format_date_range(period) do
    if Date.compare(period.starts_on, period.ends_on) == :eq do
      # Single day
      Calendar.strftime(period.starts_on, "%d.%m.")
    else
      # Date range
      "#{Calendar.strftime(period.starts_on, "%d.%m.")} - #{Calendar.strftime(period.ends_on, "%d.%m.")}"
    end
  end
end
