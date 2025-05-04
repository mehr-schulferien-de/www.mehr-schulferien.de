defmodule MehrSchulferienWeb.VacationTimelineComponent do
  use Phoenix.Component

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
    <table class="table-fixed border border-gray-300 text-center text-xs" role="presentation">
      <thead>
        <tr>
          <%= for {month_name, days_count, _year, _month} <- @months_with_days do %>
            <td colspan={days_count} class="border border-gray-200 whitespace-nowrap font-semibold text-left pl-1"><%= month_name %></td>
          <% end %>
        </tr>
      </thead>

      <tbody>
        <!-- Tageszeile -->
        <tr>
          <%= for day <- @days_to_show do %>
            <% 
              is_weekend = is_weekend?(day)
              highest_priority_period = get_highest_priority_period_for_day(@all_periods, day)
              bg_class = get_background_class(highest_priority_period, is_weekend)
            %>
            <td class={"w-6 h-5 border-t border-b border-gray-200 #{bg_class}"}></td>
          <% end %>
        </tr>
      </tbody>
    </table>

    <%= render_vacation_status(@current_vacation, @days_remaining_in_vacation, @next_vacation, @days_until_next_vacation) %>

    <div class="mt-4">
      <p class="text-sm font-medium mb-2">Ferien und Feiertage im angezeigten Zeitraum:</p>
      <ul class="text-sm">
        <%= for period <- @sorted_periods do %>
          <% 
            holiday_type = Map.get(period, :holiday_or_vacation_type, %{})
            is_school_vacation = Map.get(period, :is_school_vacation, false)
            display_name = get_display_name(holiday_type)
            marker_color = if is_school_vacation, do: "bg-green-600", else: "bg-blue-600"
          %>
          <li class={"flex items-center space-x-2 mb-1"}>
            <div class={marker_color <> " w-3 h-3 rounded-sm flex-shrink-0"}></div>
            <span>
              <%= display_name %> 
              <%= render_period_dates(period, @has_multiple_years) %>
            </span>
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
      # Default priority is 0 if not specified
      priority = Map.get(period, :display_priority, 0)
      # Return negative to sort descending (highest priority first)
      -priority
    end)
    |> List.first()
  end

  defp get_background_class(period, is_weekend) do
    cond do
      # If no periods for this day
      period == nil ->
        if is_weekend, do: "bg-gray-100", else: ""

      # Period is a school vacation
      Map.get(period, :is_school_vacation, false) ->
        "bg-green-600"

      # Period is a public holiday  
      Map.get(period, :is_public_holiday, false) ->
        "bg-blue-600"

      # Fallback for weekend
      is_weekend ->
        "bg-gray-100"

      # Default
      true ->
        ""
    end
  end

  defp render_vacation_status(current_vacation, days_remaining, next_vacation, days_until) do
    assigns = %{}

    cond do
      current_vacation && days_remaining >= 0 ->
        holiday_type = current_vacation.holiday_or_vacation_type
        display_name = get_display_name(holiday_type)

        assigns =
          Map.merge(assigns, %{
            display_name: display_name,
            days_remaining: days_remaining
          })

        ~H"""
        <div class="mt-2 text-sm font-medium">
          <div class="flex items-center">
            <span class="text-gray-500">
              <%= if @days_remaining == 0 do %>
                Aktuell sind <%= @display_name %> (letzter Tag).
              <% else %>
                Aktuell sind <%= @display_name %> (noch <%= @days_remaining %> <%= if @days_remaining == 1, do: "Tag", else: "Tage" %>).
              <% end %>
            </span>
          </div>
        </div>
        """

      next_vacation && days_until && days_until > 0 ->
        holiday_type = next_vacation.holiday_or_vacation_type
        display_name = get_display_name(holiday_type)

        assigns =
          Map.merge(assigns, %{
            display_name: display_name,
            days_until: days_until
          })

        ~H"""
        <div class="mt-2 text-sm font-medium">
          <div class="flex items-center">
            <span class="text-gray-500">
              <%= if @days_until == 1 do %>
                Noch 1 Tag bis <%= @display_name %>
              <% else %>
                Noch <%= @days_until %> Tage bis <%= @display_name %>.
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
end
