defmodule MehrSchulferienWeb.BridgeDayFormatter do
  @moduledoc """
  Shared formatting logic for bridge day data.
  Used by both MCP server and REST API v2.1 endpoints.
  """

  alias MehrSchulferien.{Periods, BridgeDayCalculations}
  alias MehrSchulferien.Periods.Grouping

  @doc """
  Calculate and format bridge days for a location and year.

  Returns a map with:
  - location: location information
  - year: the year
  - summary: aggregate statistics
  - bridge_days: list of formatted bridge day opportunities
  """
  def format_bridge_days(location, year) do
    location_ids = MehrSchulferien.Locations.recursive_location_ids(location)
    {:ok, start_date} = Date.new(year, 1, 1)
    {:ok, end_date} = Date.new(year, 12, 31)

    periods = Periods.list_public_everybody_periods(location_ids, start_date, end_date)
    bridge_day_map = Grouping.group_by_interval(periods)

    # Calculate all valid bridge days
    all_bridge_days = calculate_bridge_days(bridge_day_map, periods)

    # Calculate summary statistics
    summary = calculate_summary(all_bridge_days)

    %{
      location: format_location(location),
      year: year,
      summary: summary,
      bridge_days: all_bridge_days
    }
  end

  @doc """
  Calculate bridge days from a bridge day map and periods.
  Returns a list of formatted bridge day opportunities.
  """
  def calculate_bridge_days(bridge_day_map, periods) do
    # Loop 2..5 because that's the gap + days you take
    for num <- 2..5, bridge_day_map[num] do
      bridge_day_map[num]
      |> Enum.filter(fn bridge_day ->
        all_periods = Grouping.list_periods_with_bridge_day(periods, bridge_day)
        BridgeDayCalculations.meets_minimum_gain?(bridge_day, all_periods)
      end)
      |> Enum.map(fn bridge_day ->
        format_bridge_day(bridge_day, num, periods)
      end)
    end
    |> List.flatten()
    |> Enum.sort_by(& &1.efficiency_percentage, :desc)
  end

  @doc """
  Format a single bridge day opportunity with all details.
  """
  def format_bridge_day(bridge_day, _num, periods) do
    all_periods = Grouping.list_periods_with_bridge_day(periods, bridge_day)
    vacation_days_needed = bridge_day.number_days

    total_free =
      BridgeDayCalculations.calculate_total_consecutive_free_days(
        bridge_day,
        all_periods
      )

    gain =
      if vacation_days_needed > 0 do
        (total_free - vacation_days_needed) / vacation_days_needed * 100
      else
        0
      end

    # Find related holidays (public holidays within the timeframe)
    related_holidays =
      all_periods
      |> Enum.filter(& &1.is_public_holiday)
      |> Enum.map(&format_period/1)

    # Calculate actual timeline (including adjacent weekends)
    actual_start = find_actual_start(bridge_day.starts_on, all_periods)
    actual_end = find_actual_end(bridge_day.ends_on, all_periods)

    %{
      starts_on: Date.to_iso8601(bridge_day.starts_on),
      ends_on: Date.to_iso8601(bridge_day.ends_on),
      vacation_days_needed: vacation_days_needed,
      total_consecutive_free_days: total_free,
      efficiency_percentage: round(gain),
      category: categorize_bridge_day(vacation_days_needed),
      related_holidays: related_holidays,
      timeline: %{
        actual_starts_on: Date.to_iso8601(actual_start),
        actual_ends_on: Date.to_iso8601(actual_end),
        includes_weekends:
          actual_start != bridge_day.starts_on or actual_end != bridge_day.ends_on
      }
    }
  end

  @doc """
  Calculate summary statistics for a list of bridge days.
  """
  def calculate_summary(bridge_days) do
    total_vacation_days = Enum.sum(Enum.map(bridge_days, & &1.vacation_days_needed))
    total_free_days = Enum.sum(Enum.map(bridge_days, & &1.total_consecutive_free_days))

    overall_efficiency =
      if total_vacation_days > 0 do
        round((total_free_days - total_vacation_days) / total_vacation_days * 100)
      else
        0
      end

    %{
      total_opportunities: length(bridge_days),
      total_vacation_days_needed: total_vacation_days,
      total_free_days_gained: total_free_days,
      overall_efficiency_percentage: overall_efficiency
    }
  end

  # Private helper functions

  defp categorize_bridge_day(vacation_days_needed) do
    if vacation_days_needed == 1, do: "normal", else: "super"
  end

  defp format_location(location) do
    %{
      id: location.id,
      name: location.name,
      slug: location.slug,
      type: get_location_type(location)
    }
  end

  defp get_location_type(location) do
    cond do
      location.is_country -> "country"
      location.is_federal_state -> "federal_state"
      location.is_county -> "county"
      location.is_city -> "city"
      location.is_school -> "school"
      true -> "unknown"
    end
  end

  defp format_period(period) do
    period = MehrSchulferien.Repo.preload(period, :holiday_or_vacation_type)

    %{
      name: period.holiday_or_vacation_type.name,
      slug: period.holiday_or_vacation_type.slug,
      starts_on: Date.to_iso8601(period.starts_on),
      ends_on: Date.to_iso8601(period.ends_on),
      is_public_holiday: period.is_public_holiday
    }
  end

  # Helper to find actual start of free period (going backwards to include weekends/holidays)
  defp find_actual_start(bridge_start, all_periods) do
    Enum.reduce_while(1..30, bridge_start, fn days, acc ->
      check_date = Date.add(bridge_start, -days)

      # Check if this date is free (weekend or holiday)
      is_free =
        Date.day_of_week(check_date) > 5 or
          Enum.any?(all_periods, fn p ->
            Date.compare(check_date, p.starts_on) != :lt &&
              Date.compare(check_date, p.ends_on) != :gt
          end)

      if is_free do
        {:cont, check_date}
      else
        {:halt, acc}
      end
    end)
  end

  # Helper to find actual end of free period (going forwards to include weekends/holidays)
  defp find_actual_end(bridge_end, all_periods) do
    Enum.reduce_while(1..30, bridge_end, fn days, acc ->
      check_date = Date.add(bridge_end, days)

      # Check if this date is free (weekend or holiday)
      is_free =
        Date.day_of_week(check_date) > 5 or
          Enum.any?(all_periods, fn p ->
            Date.compare(check_date, p.starts_on) != :lt &&
              Date.compare(check_date, p.ends_on) != :gt
          end)

      if is_free do
        {:cont, check_date}
      else
        {:halt, acc}
      end
    end)
  end
end
