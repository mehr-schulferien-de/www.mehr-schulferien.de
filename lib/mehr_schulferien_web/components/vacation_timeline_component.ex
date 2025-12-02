defmodule MehrSchulferienWeb.VacationTimelineComponent do
  use Phoenix.Component

  alias MehrSchulferien.StyleConfig

  @doc """
  Renders a vacation timeline.

  ## Example
      <%= VacationTimelineComponent.render(
        days_to_show: @days_to_show,
        months: @months,
        all_periods: @all_periods,
        days_count: @days_count,
        months_with_days: @months_with_days
      ) %>
  """
  def render(opts) when is_list(opts) do
    # Convert keyword list to map
    render(Map.new(opts))
  end

  def render(assigns) when is_map(assigns) do
    # Extract timeline boundaries and filter relevant periods
    {first_day, last_day} = get_timeline_boundaries(assigns[:days_to_show])
    visible_periods = filter_visible_periods(assigns[:all_periods], first_day, last_day)
    years = extract_unique_years(visible_periods)
    has_multiple_years = length(years) > 1

    # The periods are already sorted in the SQL query by starts_on and display_priority
    sorted_periods = assigns[:all_periods]

    # Determine reference date (today)
    today = determine_reference_date(first_day, assigns)

    # Process vacation information
    {current_vacation, days_remaining_in_vacation} =
      get_current_vacation_info(sorted_periods, today)

    {next_vacation, days_until_next_vacation} =
      get_next_vacation_info(sorted_periods, today, current_vacation)

    # Update assigns with calculated values
    assigns =
      Map.merge(assigns, %{
        has_multiple_years: has_multiple_years,
        sorted_periods: sorted_periods,
        next_vacation: next_vacation,
        days_until_next_vacation: days_until_next_vacation,
        current_vacation: current_vacation,
        days_remaining_in_vacation: days_remaining_in_vacation,
        reference_date: today
      })

    render_timeline(assigns)
  end

  defp render_timeline(assigns) do
    ~H"""
    <div class="w-full overflow-hidden">
      <table class="w-full" role="presentation" style="table-layout: fixed;">
        <thead>
          <tr>
            <%= for {{month_name, days_count, _year, _month}, _index} <- Enum.with_index(@months_with_days) do %>
              <% # Calculate percentage width for this month
              percentage_width = days_count / length(@days_to_show) * 100

              # Smart abbreviation based on available space
              display_name = get_month_display_name(month_name, days_count, percentage_width) %>
              <th
                colspan={days_count}
                class="border border-gray-200 dark:border-gray-700 text-xs font-semibold text-left pl-1 overflow-hidden whitespace-nowrap text-gray-900 dark:text-gray-100"
                style={"width: #{percentage_width}%"}
                title={month_name}
              >
                {display_name}
              </th>
            <% end %>
          </tr>
        </thead>
        <tbody>
          <tr>
            <%= for day <- @days_to_show do %>
              <% is_weekend = is_weekend?(day)
              highest_priority_period = get_highest_priority_period_for_day(@all_periods, day)
              bg_class = get_background_class(highest_priority_period, is_weekend)
              cell_width = 100.0 / length(@days_to_show)
              federal_state = Map.get(assigns, :federal_state)

              # Create link if there's a period and federal state
              has_link = highest_priority_period != nil && federal_state != nil

              link_url =
                if has_link do
                  vacation_year = day.year
                  vacation_month = day.month
                  month_name = get_german_month_name(vacation_month)
                  anchor = "#{month_name}#{vacation_year}"
                  "/ferien/d/bundesland/#{federal_state.slug}/#{vacation_year}##{anchor}"
                end %>

              <%= if has_link do %>
                <td
                  class={"border border-gray-200 dark:border-gray-700 #{bg_class} p-0"}
                  style={"width: #{cell_width}%"}
                >
                  <a
                    href={link_url}
                    class="block h-5 sm:h-5 min-h-[20px] w-full hover:opacity-80 focus:opacity-80 touch-manipulation"
                    title={Calendar.strftime(day, "%d.%m.%Y")}
                    aria-label={"#{Calendar.strftime(day, "%d.%m.%Y")} - Zum Kalender"}
                  >
                  </a>
                </td>
              <% else %>
                <td
                  class={"h-5 sm:h-5 min-h-[20px] border border-gray-200 dark:border-gray-700 #{bg_class}"}
                  style={"width: #{cell_width}%"}
                >
                </td>
              <% end %>
            <% end %>
          </tr>
        </tbody>
      </table>
    </div>

    {render_vacation_status(
      @current_vacation,
      @days_remaining_in_vacation,
      @next_vacation,
      @days_until_next_vacation,
      Map.get(assigns, :federal_state)
    )}

    <div class="mt-4">
      <ul class="text-sm text-gray-900 dark:text-gray-100">
        <%= for period <- @sorted_periods do %>
          <% holiday_type = Map.get(period, :holiday_or_vacation_type, %{})
          is_school_vacation = Map.get(period, :is_school_vacation, false)
          display_name = get_display_name(holiday_type)
          federal_state = Map.get(assigns, :federal_state)

          marker_color =
            if is_school_vacation,
              do: StyleConfig.get_class(:vacation),
              else: StyleConfig.get_class(:holiday) %>
          <li class="flex items-center space-x-2 mb-1">
            <div class={marker_color <> " w-3 h-3 rounded-sm flex-shrink-0"}></div>
            <%= if federal_state do %>
              <% # Create link to vacation page with month anchor for both vacations and holidays
              period_year = period.starts_on.year
              period_month = period.starts_on.month
              month_name = get_german_month_name(period_month)
              anchor = "#{month_name}#{period_year}"
              link_url = "/ferien/d/bundesland/#{federal_state.slug}/#{period_year}##{anchor}" %>
              <a
                href={link_url}
                class="text-gray-900 dark:text-gray-100 hover:underline focus:underline active:underline inline-block py-1 -my-1"
              >
                {display_name}
                {render_period_dates(period, @has_multiple_years)}
              </a>
            <% else %>
              <span class="text-gray-900 dark:text-gray-100">
                {display_name}
                {render_period_dates(period, @has_multiple_years)}
              </span>
            <% end %>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  # ----- Data preparation functions -----

  defp get_timeline_boundaries(days) do
    {List.first(days), List.last(days)}
  end

  defp filter_visible_periods(periods, first_day, last_day) do
    Enum.filter(periods, fn period ->
      Date.compare(period.ends_on, first_day) != :lt &&
        Date.compare(period.starts_on, last_day) != :gt
    end)
  end

  defp extract_unique_years(periods) do
    periods
    |> Enum.map(& &1.starts_on.year)
    |> Enum.concat(Enum.map(periods, & &1.ends_on.year))
    |> Enum.uniq()
  end

  defp determine_reference_date(first_day, assigns) do
    cond do
      # Use first day of the timeline if available (this is provided by the controller)
      first_day != nil -> first_day
      # Use test parameter if provided (for testing)
      Map.has_key?(assigns, :_test_today) -> assigns[:_test_today]
      # Default fallback
      true -> Date.utc_today()
    end
  end

  defp get_current_vacation_info(periods, today) do
    current_vacation = find_current_vacation(periods, today)

    days_remaining =
      if current_vacation do
        Date.diff(current_vacation.ends_on, today)
      else
        nil
      end

    {current_vacation, days_remaining}
  end

  defp get_next_vacation_info(periods, today, current_vacation) do
    next_vacation =
      if current_vacation do
        nil
      else
        find_next_vacation(periods, today)
      end

    days_until =
      if next_vacation do
        Date.diff(next_vacation.starts_on, today)
      else
        nil
      end

    {next_vacation, days_until}
  end

  # ----- Timeline rendering helpers -----

  defp is_weekend?(day) do
    # 6 = Saturday, 7 = Sunday
    Date.day_of_week(day) > 5
  end

  defp get_highest_priority_period_for_day(periods, day) do
    periods
    |> Enum.filter(fn period ->
      Date.compare(day, period.starts_on) != :lt &&
        Date.compare(day, period.ends_on) != :gt
    end)
    |> Enum.sort_by(fn period ->
      # Default priority is 0 if not specified or nil
      priority = Map.get(period, :display_priority) || 0
      # Return negative to sort descending (highest priority first)
      -priority
    end)
    |> List.first()
  end

  defp get_background_class(period, is_weekend) do
    cond do
      # If no periods for this day
      period == nil ->
        if is_weekend, do: StyleConfig.get_class(:weekend), else: ""

      # Period is a school vacation
      Map.get(period, :is_school_vacation, false) ->
        # Use StyleConfig for school vacations
        StyleConfig.get_class(:vacation)

      # Period is a public holiday  
      Map.get(period, :is_public_holiday, false) ->
        StyleConfig.get_class(:holiday)

      # Fallback for weekend
      is_weekend ->
        StyleConfig.get_class(:weekend)

      # Default
      true ->
        ""
    end
  end

  defp render_vacation_status(
         current_vacation,
         days_remaining,
         next_vacation,
         days_until,
         federal_state
       ) do
    assigns = %{}

    cond do
      current_vacation && days_remaining >= 0 ->
        holiday_type = current_vacation.holiday_or_vacation_type
        display_name = get_display_name(holiday_type)

        # Add location if federal state is provided
        location_text = if federal_state, do: " in #{federal_state.name}", else: ""

        assigns =
          Map.merge(assigns, %{
            display_name: display_name,
            days_remaining: days_remaining,
            location_text: location_text
          })

        ~H"""
        <div class="mt-2 text-sm font-medium">
          <div class="flex items-center">
            <span class="text-gray-600 dark:text-gray-400">
              <%= if @days_remaining == 0 do %>
                Aktuell sind {@display_name}{@location_text} (letzter Tag).
              <% else %>
                Aktuell sind {@display_name}{@location_text} (noch {@days_remaining} {if @days_remaining ==
                                                                                           1,
                                                                                         do: "Tag",
                                                                                         else: "Tage"}).
              <% end %>
            </span>
          </div>
        </div>
        """

      next_vacation && days_until && days_until > 0 ->
        holiday_type = next_vacation.holiday_or_vacation_type
        display_name = get_display_name(holiday_type)

        # Check if the vacation name ends with "ferien" (case insensitive)
        display_format =
          if String.ends_with?(String.downcase(display_name), "ferien") do
            "zu den " <> display_name
          else
            display_name
          end

        # Add location if federal state is provided
        location_text = if federal_state, do: " in #{federal_state.name}", else: ""

        assigns =
          Map.merge(assigns, %{
            display_name: display_name,
            display_format: display_format,
            days_until: days_until,
            location_text: location_text
          })

        ~H"""
        <div class="mt-2 text-sm font-medium">
          <div class="flex items-center">
            <span class="text-gray-600 dark:text-gray-400">
              <%= if @days_until == 1 do %>
                1 Tag bis {@display_format}{@location_text}.
              <% else %>
                {@days_until} Tage bis {@display_format}{@location_text}.
              <% end %>
            </span>
          </div>
        </div>
        """

      true ->
        ~H"""
        <!-- No vacation message -->
        """
    end
  end

  defp render_period_dates(period, has_multiple_years) do
    if Date.compare(period.starts_on, period.ends_on) == :eq do
      # Single day
      if has_multiple_years do
        "(" <> Calendar.strftime(period.starts_on, "%d.%m.%Y") <> ")"
      else
        "(" <> Calendar.strftime(period.starts_on, "%d.%m.") <> ")"
      end
    else
      # Date range
      if has_multiple_years do
        "(" <>
          Calendar.strftime(period.starts_on, "%d.%m.%Y") <>
          " - " <> Calendar.strftime(period.ends_on, "%d.%m.%Y") <> ")"
      else
        "(" <>
          Calendar.strftime(period.starts_on, "%d.%m.") <>
          " - " <> Calendar.strftime(period.ends_on, "%d.%m.") <> ")"
      end
    end
  end

  # Gets the display name, preferring colloquial name over formal name
  defp get_display_name(holiday_type) do
    # First try to get colloquial name, then fall back to regular name
    Map.get(holiday_type, :colloquial, Map.get(holiday_type, :name, ""))
  end

  # Finds the current vacation period (if today is within a vacation)
  defp find_current_vacation(periods, today) do
    periods
    |> Enum.find(fn period ->
      # Only include school vacations
      # Check if today is within the vacation period
      Map.get(period, :is_school_vacation, false) &&
        Date.compare(period.starts_on, today) != :gt &&
        Date.compare(period.ends_on, today) != :lt
    end)
  end

  # Finds the next upcoming vacation period (only school vacations, not public holidays)
  defp find_next_vacation(periods, today) do
    periods
    |> Enum.filter(fn period ->
      # Only include school vacations
      # Only include future periods
      Map.get(period, :is_school_vacation, false) &&
        Date.compare(period.starts_on, today) == :gt
    end)
    |> Enum.sort_by(& &1.starts_on, Date)
    |> List.first()
  end

  # Get German month name for anchor links
  defp get_german_month_name(month_number) do
    case month_number do
      1 -> "januar"
      2 -> "februar"
      3 -> "maerz"
      4 -> "april"
      5 -> "mai"
      6 -> "juni"
      7 -> "juli"
      8 -> "august"
      9 -> "september"
      10 -> "oktober"
      11 -> "november"
      12 -> "dezember"
      _ -> ""
    end
  end

  # Smart month name display based on available space
  defp get_month_display_name(month_name, days_count, _percentage_width) do
    cond do
      # 1-3 days: Just first letter
      days_count <= 3 ->
        String.at(month_name, 0) <> "."

      # 4-6 days: Very short abbreviation (3 letters)
      days_count <= 6 ->
        case month_name do
          "Januar" -> "Jan."
          "Februar" -> "Feb."
          "März" -> "Mär."
          "April" -> "Apr."
          "Mai" -> "Mai"
          "Juni" -> "Jun."
          "Juli" -> "Jul."
          "August" -> "Aug."
          "September" -> "Sep."
          "Oktober" -> "Okt."
          "November" -> "Nov."
          "Dezember" -> "Dez."
          _ -> String.slice(month_name, 0, 3) <> "."
        end

      # 7-10 days: 4-letter abbreviation where needed
      days_count <= 10 ->
        case month_name do
          "September" -> "Sept."
          "November" -> "Nov."
          "Dezember" -> "Dez."
          _ -> month_name
        end

      # More than 10 days: Full name
      true ->
        month_name
    end
  end
end
