defmodule MehrSchulferienWeb.FederalState.Helpers do
  @moduledoc """
  Helper functions for the federal state templates.
  """

  @doc """
  Calculate the effective duration of a period, taking into account
  any overlapping periods.
  """
  def calculate_effective_duration(period, all_periods) do
    start_date = period.starts_on
    end_date = period.ends_on
    days = Date.diff(end_date, start_date) + 1

    # Look for adjacent weekends or holidays
    # Check if we need to extend the period at the beginning
    {current_start, current_end} = {start_date, end_date}

    # Check days before the period
    days_before = check_days_before(current_start, all_periods)
    days_after = check_days_after(current_end, all_periods)

    days + days_before + days_after
  end

  # Check the days before the period for holidays and weekend days
  defp check_days_before(start_date, all_periods) do
    # Get the previous day
    prev_date = Date.add(start_date, -1)

    # If it's a weekend or holiday, add it and check the day before recursively
    if is_weekend?(prev_date) || is_holiday?(prev_date, all_periods) do
      1 + check_days_before(prev_date, all_periods)
    else
      0
    end
  end

  # Check the days after the period for holidays and weekend days
  defp check_days_after(end_date, all_periods) do
    # Get the next day
    next_date = Date.add(end_date, 1)

    # If it's a weekend or holiday, add it and check the next day recursively
    if is_weekend?(next_date) || is_holiday?(next_date, all_periods) do
      1 + check_days_after(next_date, all_periods)
    else
      0
    end
  end

  # Check if a date is a weekend day
  defp is_weekend?(date) do
    day_of_week = Date.day_of_week(date)
    day_of_week == 6 || day_of_week == 7
  end

  # Check if a date is a holiday or in a vacation period
  defp is_holiday?(date, all_periods) do
    Enum.any?(all_periods, fn period ->
      Date.compare(period.starts_on, date) != :gt &&
        Date.compare(period.ends_on, date) != :lt
    end)
  end
end
