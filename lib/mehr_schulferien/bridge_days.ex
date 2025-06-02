defmodule MehrSchulferien.BridgeDays do
  @moduledoc """
  Functions for calculating and handling bridge days.
  """

  alias MehrSchulferien.{Locations, Calendars.DateHelpers, Repo}
  alias MehrSchulferien.Periods.{Query, Grouping}
  alias MehrSchulferienWeb.BridgeDayView

  @doc """
  Returns whether a location has bridge days for a specific year.
  NOTE: This function currently delegates to a function within the Web context
  (`MehrSchulferienWeb.BridgeDayController.has_bridge_days?/2`).
  This creates a dependency from the core logic to the web interface, which is
  generally discouraged. Consider refactoring to move the underlying logic
  into this context or a shared utility if appropriate.
  """
  def has_bridge_days?(location_ids, year) do
    MehrSchulferienWeb.BridgeDayController.has_bridge_days?(location_ids, year)
  end

  @doc """
  Calculates bridge day efficiency metrics.
  NOTE: This function currently returns hardcoded values.
  It's a placeholder and would need to be implemented with actual calculation
  logic, possibly involving database queries or more complex computations based on
  real bridge day data, to be meaningful.

  Returns a map with vacation_days, total_free_days, and efficiency_percentage.

  ## Examples

      iex> calculate_bridge_day_efficiency()
      %{vacation_days: 1, total_free_days: 4, efficiency_percentage: 300}
  """
  def calculate_bridge_day_efficiency do
    # This is a simplified version that could be expanded with more complex SQL logic
    # if needed to calculate based on real bridge day data
    query = "SELECT 1 as vacation_days, 4 as total_free_days, 300 as efficiency_percentage"

    result = Repo.query!(query, [])

    # The result structure from Repo.query! is %Postgrex.Result{rows: [[val1, val2, ...]], ...}
    # or %Mariaex.Result for MySQL. We expect one row with three values.
    case result.rows do
      [[vacation_days, total_free_days, efficiency_percentage]] ->
        %{
          vacation_days: vacation_days,
          total_free_days: total_free_days,
          efficiency_percentage: efficiency_percentage
        }
      _ ->
        # Handle unexpected query result, e.g., by logging or raising
        # For now, returning a default or error map might be suitable
        Logger.error("Failed to calculate bridge day efficiency from DB query, unexpected result: #{inspect(result)}")
        %{vacation_days: 0, total_free_days: 0, efficiency_percentage: 0} # Default/error state
    end
  end

  @doc """
  Calculates the best bridge day deal for teaser purposes.
  It specifically targets North Rhine-Westphalia ("nordrhein-westfalen") in Germany ("d")
  for the current year.

  The function attempts to find the bridge day opportunity (gap between fixed holidays)
  that yields the highest percentage gain in terms of total free days versus vacation days taken.

  Returns a tuple: `{percent_gain, vacation_days_taken, total_free_days_achieved, year, gap_start_date, gap_end_date}`
  or `nil` if no suitable bridge day is found or an error occurs.

  NOTE: The generic `rescue _ -> nil` can hide errors. Consider more specific error handling
  or logging for robustness in a production environment.
  The dependency on `BridgeDayView.get_number_max_days/1` also introduces coupling
  with the web layer.
  """
  def best_bridge_day_teaser do
    try do
      today = DateHelpers.today_berlin()
      current_year = today.year

      # Hardcoded to Germany and North Rhine-Westphalia for the teaser.
      country_slug = "d"
      federal_state_slug = "nordrhein-westfalen"

      country = Locations.get_country_by_slug!(country_slug)
      # Fetch federal state within the context of the country to ensure it's the correct one.
      # Assuming get_federal_state_by_slug! takes country struct or ID.
      # Based on Locations.ex, it takes (slug, country_struct).
      north_rhine_westphalia = Locations.get_federal_state_by_slug!(federal_state_slug, country)

      location_ids = [country.id, north_rhine_westphalia.id]

      # Define the period for which to search for public holidays.
      {:ok, start_date_of_year} = Date.new(current_year, 1, 1)
      {:ok, end_date_of_year} = Date.new(current_year, 12, 31)

      # Get all public holidays and general "valid for everybody" periods (like weekends).
      public_periods =
        Query.list_public_everybody_periods(location_ids, start_date_of_year, end_date_of_year)

      # Identify potential bridge day gaps between these periods.
      bridge_day_map = Grouping.group_by_interval(public_periods)

      # Flatten all identified bridge day gaps into a single list.
      all_potential_gaps = List.flatten(Enum.map(bridge_day_map, fn {_gap_size, gaps_list} -> gaps_list || [] end))

      # Find the "best" deal among these gaps.
      best_deal =
        all_potential_gaps
        |> Enum.max_by(
          # Calculation logic to determine "best":
          # It reconstructs the sequence of periods including the bridge day (gap)
          # then uses BridgeDayView to calculate total free days.
          # The score is the percentage increase of free days over vacation days.
          fn bridge_day_gap ->
            # `bridge_day_gap` is a BridgeDayPeriod struct.
            # `list_periods_with_bridge_day` expects the gap itself as the second argument.
            # It then finds consecutive fixed holidays around this gap.
            periods_sequence = Grouping.list_periods_with_bridge_day(public_periods, bridge_day_gap)
            total_free_days_achieved = BridgeDayView.get_number_max_days(periods_sequence)
            # `bridge_day_gap.number_days` is the number of work days taken for vacation.
            vacation_days_taken = bridge_day_gap.number_days
            if vacation_days_taken > 0 do
              round((total_free_days_achieved - vacation_days_taken) / vacation_days_taken * 100)
            else
              0 # Avoid division by zero if a gap somehow has 0 days (should not happen for 2..5 diffs)
            end
          end,
          fn -> nil end # Default if all_potential_gaps is empty or all scores are 0.
        )

      # If a best deal is found, format and return its details.
      if best_deal do
        periods_sequence = Grouping.list_periods_with_bridge_day(public_periods, best_deal)
        total_free_days_achieved = BridgeDayView.get_number_max_days(periods_sequence)
        vacation_days_taken = best_deal.number_days
        percent_gain = if vacation_days_taken > 0, do: round((total_free_days_achieved - vacation_days_taken) / vacation_days_taken * 100), else: 0

        {percent_gain, vacation_days_taken, total_free_days_achieved, current_year, best_deal.starts_on, best_deal.ends_on}
      else
        nil # No bridge day opportunity found.
      end
    rescue
      # Catch any error during the process and return nil.
      # It's better to log the error for debugging purposes.
      # e.g., Logger.error("Error in best_bridge_day_teaser: #{inspect(exception)}")
      exception ->
        Logger.error("Error in best_bridge_day_teaser: #{inspect(exception)} Stacktrace: #{inspect(__STACKTRACE__)}")
        nil
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

  @doc """
  Finds the most efficient bridge day opportunity in the next specified months from the given date.
  Considers using 1-5 vacation days to maximize free time.

  Returns a map containing:
  - best_opportunity: A BridgeDayPeriod struct
  - vacation_days: Number of vacation days used
  - total_free_days: Total number of consecutive free days achieved
  - efficiency_percentage: Percentage efficiency gain (total free days / vacation days)
  - adjacent_periods: List of adjacent periods that form the opportunity

  Returns nil if no opportunities are found.

  ## Parameters

  - federal_state: The federal state to search for bridge days
  - start_date: The date from which to start searching
  - months_ahead: The number of months to look ahead (defaults to 12)

  ## Examples

      iex> find_best_bridge_day(federal_state, ~D[2023-01-01])
      %{
        bridge_day: %BridgeDayPeriod{...}, # Changed from best_opportunity to bridge_day for consistency
        vacation_days: 1,
        total_free_days: 4,
        efficiency_percentage: 300,
        adjacent_periods: [...]
      }
  """
  def find_best_bridge_day(federal_state, start_date, months_ahead \\ 12) do
    # Get the country of the federal state
    country = Locations.get_location!(federal_state.parent_location_id)
    location_ids = [country.id, federal_state.id]

    # Calculate end date based on months_ahead parameter
    end_date = Date.add(start_date, months_ahead * 30)

    # Fetch all public periods in the specified time window
    public_periods = Query.list_public_everybody_periods(location_ids, start_date, end_date)

    # Early return if we don't have enough periods
    if length(public_periods) < 2 do
      nil
    else
      # Find all potential bridge day opportunities (1-5 days)
      bridge_day_map = Grouping.group_by_interval(public_periods)

      # Collect all opportunities with 1-5 vacation days
      opportunities =
        for days <- 2..6,
            bridge_days = Map.get(bridge_day_map, days, []),
            length(bridge_days) > 0 do
          vacation_days = days - 1

          # Analyze each bridge day opportunity in this category
          bridge_days
          |> Enum.filter(&(Date.compare(&1.starts_on, start_date) == :gt))
          |> Enum.map(fn bridge_day ->
            periods = Grouping.list_periods_with_bridge_day(public_periods, bridge_day)
            total_free_days = BridgeDayView.get_number_max_days(periods)
            efficiency_percentage = round((total_free_days - vacation_days) / vacation_days * 100)

            %{
              bridge_day: bridge_day,
              vacation_days: vacation_days,
              total_free_days: total_free_days,
              efficiency_percentage: efficiency_percentage,
              adjacent_periods: periods
            }
          end)
        end
        |> List.flatten()

      # Find the best opportunity - prioritize total free days first, then efficiency
      # This ensures we get longer continuous periods off when possible
      Enum.max_by(
        opportunities,
        fn opportunity ->
          # Create a composite score where total free days is the primary factor
          # and efficiency is the secondary factor (as a tiebreaker)
          opportunity.total_free_days * 1000 + opportunity.efficiency_percentage
        end,
        fn -> nil end
      )
    end
  end
end
