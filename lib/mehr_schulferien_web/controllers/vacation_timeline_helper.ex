defmodule MehrSchulferienWeb.VacationTimelineHelper do
  @doc """
  Prepares the data required for the vacation timeline component.
  """
  def prepare_timeline_data(assigns) do
    # Get today's date as a backup
    today = MehrSchulferien.Calendars.DateHelpers.today_berlin()

    # Check for a custom date parameter
    first_day =
      cond do
        Map.has_key?(assigns, :custom_start_date) && assigns.custom_start_date != nil ->
          assigns.custom_start_date

        Map.has_key?(assigns, :days) && is_list(assigns.days) && length(assigns.days) > 0 ->
          days = assigns.days
          List.first(days)

        true ->
          today
      end

    # Use custom days count or default to 90
    days_count = Map.get(assigns, :days_to_display, 90)

    # Create days to show based on first_day
    days_to_show = MehrSchulferien.Calendars.DateHelpers.create_days(first_day, days_count)

    # Default periods to empty list if not provided
    periods = Map.get(assigns, :periods, [])

    # Monate identifizieren und gruppieren
    month_groups =
      days_to_show
      |> Enum.group_by(fn day -> {day.year, day.month} end)
      |> Enum.sort()

    # Monatsnamen und Anzahl der Tage in jedem Monat
    months = Map.get(assigns, :months, %{})

    months_with_days =
      Enum.map(month_groups, fn {{year, month}, days} ->
        month_name = Map.get(months, month, "") |> to_string()
        {month_name, length(days), year, month}
      end)

    # The periods are already filtered and sorted by the SQL query
    # Just use them directly without additional filtering or sorting
    all_periods = periods

    %{
      days_to_show: days_to_show,
      days_count: days_count,
      months_with_days: months_with_days,
      all_periods: all_periods
    }
  end
end
