defmodule MehrSchulferien.BridgeDayCalculations do
  @moduledoc """
  Core business logic for bridge day calculations.
  These functions calculate metrics about bridge days without any view concerns.
  """

  @doc """
  Calculates the total number of free days in a sequence of periods.
  """
  def get_number_max_days(periods) when is_list(periods) and periods != [] do
    start_date = hd(periods).starts_on
    end_date = List.last(periods).ends_on
    Date.diff(end_date, start_date) + 1
  end

  def get_number_max_days([]), do: 0

  @doc """
  Calculates the actual total consecutive free days for a bridge day,
  including adjacent weekends and holidays.

  This properly counts all consecutive free days by:
  1. Starting from the bridge day period
  2. Expanding backwards to include adjacent weekends/holidays
  3. Expanding forwards to include adjacent weekends/holidays
  """
  def calculate_total_consecutive_free_days(bridge_day, all_periods) do
    # Helper function to check if a date is free (weekend or holiday)
    is_free_day = fn date ->
      is_weekend = Date.day_of_week(date) > 5

      is_holiday =
        Enum.any?(all_periods, fn p ->
          Date.compare(date, p.starts_on) != :lt &&
            Date.compare(date, p.ends_on) != :gt
        end)

      is_weekend || is_holiday
    end

    # The bridge day period itself is always considered free
    # (it's a vacation day that the employee takes)
    is_free_or_bridge = fn date ->
      is_in_bridge =
        Date.compare(date, bridge_day.starts_on) != :lt &&
          Date.compare(date, bridge_day.ends_on) != :gt

      is_in_bridge || is_free_day.(date)
    end

    # Find the actual start by going backwards from bridge day start
    # Stop when we hit a non-free day (working day)
    actual_start =
      Enum.reduce_while(1..30, bridge_day.starts_on, fn days, acc ->
        check_date = Date.add(bridge_day.starts_on, -days)
        prev_date = Date.add(check_date, 1)

        # Check if the previous date (closer to bridge day) is free
        if is_free_or_bridge.(prev_date) do
          # If current date is also free, continue expanding
          if is_free_day.(check_date) do
            {:cont, check_date}
          else
            # Hit a working day, stop here
            {:halt, acc}
          end
        else
          # There's a gap, stop at previous position
          {:halt, acc}
        end
      end)

    # Find the actual end by going forwards from bridge day end
    # Stop when we hit a non-free day (working day)
    actual_end =
      Enum.reduce_while(1..30, bridge_day.ends_on, fn days, acc ->
        check_date = Date.add(bridge_day.ends_on, days)
        prev_date = Date.add(check_date, -1)

        # Check if the previous date (closer to bridge day) is free
        if is_free_or_bridge.(prev_date) do
          # If current date is also free, continue expanding
          if is_free_day.(check_date) do
            {:cont, check_date}
          else
            # Hit a working day, stop here
            {:halt, acc}
          end
        else
          # There's a gap, stop at previous position
          {:halt, acc}
        end
      end)

    # Calculate the total free days
    Date.diff(actual_end, actual_start) + 1
  end

  @doc """
  Determines if a bridge day opportunity meets the minimum gain threshold.

  The minimum gain is based on how many vacation days you take versus
  how many total free days you get. Must deliver more than 100% gain.
  """
  def meets_minimum_gain?(bridge_day, periods) do
    vacation_days = bridge_day.number_days

    # If the bridge_day has starts_on and ends_on, use the accurate calculation
    # Otherwise fall back to the simpler calculation for backward compatibility
    total_free_days =
      if Map.has_key?(bridge_day, :starts_on) and Map.has_key?(bridge_day, :ends_on) do
        calculate_total_consecutive_free_days(bridge_day, periods)
      else
        get_number_max_days(periods)
      end

    # Calculate the gain percentage
    gain_percentage =
      if vacation_days > 0 do
        (total_free_days - vacation_days) / vacation_days * 100
      else
        0
      end

    # Must have more than 100% gain
    gain_percentage > 100
  end
end
