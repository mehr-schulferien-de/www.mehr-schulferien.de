defmodule MehrSchulferien.BridgeDays do
  @moduledoc """
  Functions for calculating and handling bridge days.
  """

  alias MehrSchulferien.{Locations, Calendars.DateHelpers}
  alias MehrSchulferien.Periods.{Query, Grouping}
  alias MehrSchulferienWeb.BridgeDayView

  @doc """
  Returns whether a location has bridge days for a specific year.
  """
  def has_bridge_days?(location_ids, year) do
    MehrSchulferienWeb.BridgeDayController.has_bridge_days?(location_ids, year)
  end

  @doc """
  Calculates the best bridge day deal for teaser purposes.
  Uses NRW (largest state) as the example.
  """
  def best_bridge_day_teaser do
    try do
      today = DateHelpers.today_berlin()
      current_year = today.year
      country = Locations.get_country_by_slug!("d")
      federal_states = Locations.list_federal_states(country)
      north_rhine_westphalia = Enum.find(federal_states, &(&1.slug == "nordrhein-westfalen"))
      location_ids = [country.id, north_rhine_westphalia.id]
      {:ok, start_date} = Date.new(current_year, 1, 1)
      {:ok, end_date} = Date.new(current_year, 12, 31)
      public_periods = Query.list_public_everybody_periods(location_ids, start_date, end_date)
      bridge_day_map = Grouping.group_by_interval(public_periods)

      best_deal =
        List.flatten(Enum.map(bridge_day_map, fn {_k, v} -> v || [] end))
        |> Enum.max_by(
          fn bridge_day ->
            periods = Grouping.list_periods_with_bridge_day(public_periods, bridge_day)
            max_days = BridgeDayView.get_number_max_days(periods)
            percent = round((max_days - bridge_day.number_days) / bridge_day.number_days * 100)
            percent
          end,
          fn -> nil end
        )

      if best_deal do
        periods = Grouping.list_periods_with_bridge_day(public_periods, best_deal)
        max_days = BridgeDayView.get_number_max_days(periods)
        min_leave = best_deal.number_days
        percent = round((max_days - min_leave) / min_leave * 100)
        {percent, min_leave, max_days, current_year, best_deal.starts_on, best_deal.ends_on}
      else
        nil
      end
    rescue
      _ -> nil
    end
  end

  @doc """
  Finds the next available bridge day for a federal state, starting from the given date.

  Returns a BridgeDayPeriod struct if a bridge day is found, or nil if no bridge day is available.

  ## Parameters

  - federal_state: The federal state to search for bridge days
  - current_date: The date from which to start searching
  - days_count: Optional parameter specifying the number of days for the bridge day (defaults to 1)

  ## Examples

      iex> find_next_bridge_day(federal_state, ~D[2023-01-01])
      %BridgeDayPeriod{...}
      
      iex> find_next_bridge_day(federal_state, ~D[2023-01-01], 2)
      %BridgeDayPeriod{...}
  """
  def find_next_bridge_day(federal_state, current_date, days_count \\ 1) do
    # Get the country of the federal state
    country = Locations.get_location!(federal_state.parent_location_id)
    location_ids = [country.id, federal_state.id]

    # Use progressive search to minimize data retrieval
    # First try a 6-month window, then expand if needed
    result = find_next_bridge_day_in_window(location_ids, current_date, days_count, 6)

    if result do
      result
    else
      # Try a 1-year window if no results in 6 months
      result = find_next_bridge_day_in_window(location_ids, current_date, days_count, 12)

      if result do
        result
      else
        # Finally try a 2-year window if still no results
        find_next_bridge_day_in_window(location_ids, current_date, days_count, 24)
      end
    end
  end

  # Helper function to search for bridge days within a specific month window
  defp find_next_bridge_day_in_window(location_ids, current_date, days_count, months) do
    # Calculate window end date based on the specified number of months
    end_date = Date.add(current_date, months * 30)

    # Fetch public periods only within this window
    public_periods = Query.list_public_everybody_periods(location_ids, current_date, end_date)

    # Early return if we don't have enough periods to form bridge days
    if length(public_periods) < 2 do
      nil
    else
      # Analyze periods to find bridge days
      bridge_day_map = Grouping.group_by_interval(public_periods)

      # Find bridge days with the requested number of days
      bridge_days = Map.get(bridge_day_map, days_count + 1, [])

      # Return the earliest bridge day (already sorted by starts_on from the query)
      bridge_days
      |> Enum.filter(&(Date.compare(&1.starts_on, current_date) == :gt))
      |> List.first()
    end
  end
end
