defmodule MehrSchulferienWeb.FederalState.PartialDataComponent do
  use Phoenix.Component

  attr :periods, :list, required: true
  attr :federal_state, :map, required: true
  attr :year, :integer, required: true

  def partial_data(assigns) do
    # Check if we have data for the next school year
    has_partial_data = missing_next_school_year_data?(assigns.periods, assigns.year)

    # Only render warning if we truly have partial data
    if has_partial_data do
      assigns = assign(assigns, :has_partial_data, has_partial_data)

      ~H"""
      <div class="bg-blue-100 border-l-4 border-blue-500 text-blue-700 p-4 my-4" role="alert">
        <p class="font-bold">Hinweis zu den Feriendaten</p>
        <p>
          Für das Jahr <%= @year %> sind aktuell nur die Ferien bis einschließlich der Sommerferien eingetragen.
          Die Ferientermine für das Schuljahr <%= @year %>/<%= @year + 1 %> werden bald nachgetragen.
        </p>
      </div>
      """
    else
      assigns = assign(assigns, :has_partial_data, false)
      ~H""
    end
  end

  # Function to determine if the next school year data is missing
  # In Germany, the school year starts around August 1st, but may start later
  # if Sommerferien is still going on
  def missing_next_school_year_data?(periods, year) do
    # Define the nominal start of the school year (August 1st)
    nominal_school_year_start = Date.new!(year, 8, 1)

    # Get the last period date
    last_period_date =
      periods
      |> Enum.sort_by(& &1.ends_on, {:desc, Date})
      |> List.first()
      |> case do
        nil -> nil
        period -> period.ends_on
      end

    # If we have no periods at all
    if last_period_date == nil do
      false
    else
      # Find Sommerferien that might extend past August 1st
      sommerferien =
        Enum.find(periods, fn period ->
          # Looking for Sommerferien that extend past the nominal school year start
          is_summer_vacation = is_summer_vacation?(period)

          is_summer_vacation && Date.compare(period.ends_on, nominal_school_year_start) == :gt
        end)

      # Determine the actual school year start
      actual_school_year_start =
        case sommerferien do
          nil -> nominal_school_year_start
          # Day after Sommerferien ends
          period -> Date.add(period.ends_on, 1)
        end

      # Find any periods that are truly in the next school year (after Sommerferien)
      next_school_year_periods =
        Enum.filter(periods, fn period ->
          # Exclude any periods that are part of the current school year
          Date.compare(period.starts_on, actual_school_year_start) == :gt &&
            !(is_summer_vacation?(period) &&
                Date.compare(period.starts_on, nominal_school_year_start) in [:lt, :eq])
        end)

      # Do we have any periods in the next school year?
      length(next_school_year_periods) == 0
    end
  end

  # Function to determine if a specific month should be crossed out
  # This considers whether the month is part of the current school year or next
  def should_cross_out_month?(month, year, periods) do
    # If we're missing data for the next school year
    if missing_next_school_year_data?(periods, year) do
      # Get the date for the 1st of this month
      month_start = Date.new!(year, month, 1)

      # Find Sommerferien that might extend past August 1st
      sommerferien =
        Enum.find(periods, fn period ->
          is_summer_vacation?(period) &&
            Date.compare(period.ends_on, Date.new!(year, 8, 1)) == :gt
        end)

      # Determine when the next school year actually starts
      next_school_year_start =
        case sommerferien do
          nil -> Date.new!(year, 8, 1)
          # Day after Sommerferien ends
          period -> Date.add(period.ends_on, 1)
        end

      # Check if this month starts after the next school year starts
      # and is not covered by any existing period (e.g. Sommerferien extending into September)
      month_in_next_school_year = Date.compare(month_start, next_school_year_start) in [:gt, :eq]

      month_covered_by_periods =
        Enum.any?(periods, fn period ->
          month_in_period =
            month == period.starts_on.month ||
              month == period.ends_on.month ||
              (period.starts_on.month < month && period.ends_on.month > month)

          month_in_period && Date.compare(period.ends_on, month_start) == :gt
        end)

      month_in_next_school_year && !month_covered_by_periods
    else
      false
    end
  end

  # Helper function to check if a period is Sommerferien
  defp is_summer_vacation?(period) do
    if period.holiday_or_vacation_type do
      name = period.holiday_or_vacation_type.name || ""
      colloquial = period.holiday_or_vacation_type.colloquial || ""

      String.contains?(String.downcase(name), "sommer") ||
        String.contains?(String.downcase(colloquial), "sommer")
    else
      false
    end
  end

  # Function to determine the last month with data
  def get_last_data_month(periods) do
    periods
    |> Enum.sort_by(& &1.ends_on, {:desc, Date})
    |> List.first()
    |> case do
      # If no periods, assume full year
      nil -> 12
      period -> period.ends_on.month
    end
  end

  # Function to check if a month should be crossed out - no longer used directly
  # but keeping for reference
  def should_cross_out?(month, _year, periods) do
    last_month = get_last_data_month(periods)
    month > last_month
  end
end
