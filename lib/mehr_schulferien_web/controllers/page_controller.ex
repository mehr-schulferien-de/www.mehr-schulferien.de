defmodule MehrSchulferienWeb.PageController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods, BridgeDays}

  def index(conn, %{"number_of_days" => number_of_days}) do
    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year
    ends_on = Date.add(today, number_of_days)
    days = DateHelpers.create_days(today, number_of_days)
    day_names = DateHelpers.short_days_map()
    months = DateHelpers.get_months_map()

    # Calculate months_with_days for the timeline
    month_groups =
      days
      |> Enum.group_by(fn day -> {day.year, day.month} end)
      |> Enum.sort()

    months_with_days =
      Enum.map(month_groups, fn {{year, month}, month_days} ->
        month_name = Map.get(months, month, "") |> to_string()
        {month_name, length(month_days), year, month}
      end)

    # Fetch everything in a more efficient way
    countries = fetch_countries_with_periods(today, ends_on, current_year)

    render(conn, "index.html",
      countries: countries,
      days: days,
      day_names: day_names,
      months: months,
      current_year: current_year,
      number_of_days: number_of_days,
      months_with_days: months_with_days
    )
  end

  def index(conn, _params) do
    index(conn, %{"number_of_days" => 80})
  end

  def summer_vacations(conn, _params) do
    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year
    # 20.6. + 87 Tage = 15.9.
    number_of_days = 87

    # Start der Sommerferien (irgendwo)
    {:ok, fixed_start_date} = Date.from_erl({current_year, 6, 20})

    # Only use fixed start date if we're not using a custom date
    today = if conn.assigns.custom_date, do: today, else: fixed_start_date

    ends_on = Date.add(today, number_of_days)
    days = DateHelpers.create_days(today, number_of_days)
    day_names = DateHelpers.short_days_map()
    months = DateHelpers.get_months_map()

    # Calculate months_with_days for the timeline
    month_groups =
      days
      |> Enum.group_by(fn day -> {day.year, day.month} end)
      |> Enum.sort()

    months_with_days =
      Enum.map(month_groups, fn {{year, month}, month_days} ->
        month_name = Map.get(months, month, "") |> to_string()
        {month_name, length(month_days), year, month}
      end)

    # Fetch everything in a more efficient way
    countries = fetch_countries_with_periods(today, ends_on, current_year)

    render(conn, "summer_vacations.html",
      countries: countries,
      days: days,
      day_names: day_names,
      months: months,
      current_year: current_year,
      number_of_days: number_of_days,
      months_with_days: months_with_days
    )
  end

  def full_year(conn, _params) do
    index(conn, %{"number_of_days" => 366})
  end

  def developers(conn, _params) do
    render(conn, "developers.html", css_framework: :tailwind)
  end

  def impressum(conn, _params) do
    render(conn, "impressum.html")
  end

  def new(conn, params) do
    # Parse days parameter
    days_to_display = parse_days_count(params["days"])

    # Use our custom date or the current date
    today = DateHelpers.get_today_or_custom_date(conn)

    # We don't need to set noindex here as it's already set by the DateAssignsPlug
    # when a custom date is present

    # Use the actual start date for year calculation
    current_year = today.year
    number_of_days = days_to_display
    ends_on = Date.add(today, number_of_days)

    # Generate calendar data
    days = DateHelpers.create_days(today, number_of_days)
    day_names = DateHelpers.short_days_map()
    months = DateHelpers.get_months_map()
    months_with_days = calculate_months_with_days(days, months)

    # Fetch countries data
    countries = fetch_countries_with_periods(today, ends_on, current_year)

    render(conn, "new.html",
      countries: countries,
      days: days,
      day_names: day_names,
      months: months,
      current_year: current_year,
      number_of_days: number_of_days,
      css_framework: :tailwind_new,
      custom_start_date: conn.assigns.custom_date,
      days_to_display: days_to_display,
      months_with_days: months_with_days
    )
  end

  # Parses and validates the days count
  defp parse_days_count(nil), do: 80

  defp parse_days_count(days_str) do
    case Integer.parse(days_str) do
      {days, _} when days > 0 and days <= 365 -> days
      _ -> 80
    end
  end

  # Calculates the months with days for the timeline
  defp calculate_months_with_days(days, months) do
    days
    |> Enum.group_by(fn day -> {day.year, day.month} end)
    |> Enum.sort()
    |> Enum.map(fn {{year, month}, month_days} ->
      month_name = Map.get(months, month, "") |> to_string()
      {month_name, length(month_days), year, month}
    end)
  end

  # This function fetches all data in a more efficient way
  defp fetch_countries_with_periods(start_date, ends_on, current_year) do
    # Get countries and their federal states in a more efficient way (2 queries instead of N+1)
    countries_with_federal_states = Locations.list_countries_with_related_data()

    # Create a list of all location IDs for periods query
    all_location_ids =
      Enum.flat_map(countries_with_federal_states, fn {country, federal_states} ->
        [country.id | Enum.map(federal_states, & &1.id)]
      end)

    # Get all periods in a single query
    all_periods =
      Periods.list_school_free_periods_with_preload(all_location_ids, start_date, ends_on)

    # Group periods by location_id for efficient lookup
    periods_by_location = Enum.group_by(all_periods, & &1.location_id)

    # Build the final data structure
    Enum.map(countries_with_federal_states, fn {country, federal_states} ->
      # Get country periods
      country_periods = Map.get(periods_by_location, country.id, [])

      # Process federal states
      federal_states_with_bridge_days =
        Enum.map(federal_states, fn state ->
          # Add bridge days info
          years_with_bridge_days =
            Enum.filter(current_year..(current_year + 2), fn year ->
              BridgeDays.has_bridge_days?(
                [country.id, state.id],
                year
              )
            end)

          Map.put(state, :years_with_bridge_days, years_with_bridge_days)
        end)

      # Create periods entries for each federal state
      periods =
        Enum.map(federal_states_with_bridge_days, fn state ->
          state_periods = Map.get(periods_by_location, state.id, [])
          {state, country_periods ++ state_periods}
        end)

      # Return the final country entry
      %{
        country: country,
        federal_states: federal_states_with_bridge_days,
        periods: periods
      }
    end)
  end
end
