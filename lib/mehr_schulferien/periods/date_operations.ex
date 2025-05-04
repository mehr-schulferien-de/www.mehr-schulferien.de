defmodule MehrSchulferien.Periods.DateOperations do
  @moduledoc """
  Date-related operations for periods.

  This module contains functions for finding, filtering, and analyzing
  periods based on dates or date ranges.
  """

  alias MehrSchulferien.Calendars.DateHelpers

  @doc """
  Finds all the holiday periods for a certain date.
  """
  def find_all_periods(periods, date) do
    Enum.filter(periods, &is_holiday?(&1, date))
  end

  @doc """
  Returns the next schoolday (the next day that is not a holiday).
  """
  def find_next_schoolday([], _), do: nil

  def find_next_schoolday([first | rest], date) do
    if is_holiday?(first, date) do
      new_date = Date.add(first.ends_on, 1)
      find_next_schoolday(rest, new_date)
    else
      if check_ends_on(date, first) do
        date
      else
        find_next_schoolday(rest, date)
      end
    end
  end

  defp is_holiday?(period, date) do
    case Date.compare(date, period.starts_on) do
      :lt -> false
      :eq -> true
      :gt -> check_ends_on(date, period)
    end
  end

  defp check_ends_on(date, first) do
    case Date.compare(date, first.ends_on) do
      :gt -> nil
      _ -> first
    end
  end

  @doc """
  Returns the holiday periods for a certain date's month.
  """
  def find_periods_by_month(_date, []), do: []

  def find_periods_by_month(date, [first | rest]) do
    if DateHelpers.compare_by_month(date, first.starts_on) == :lt do
      []
    else
      if DateHelpers.compare_by_month(date, first.ends_on) == :gt do
        find_periods_by_month(date, rest)
      else
        [first | find_periods_by_month(date, rest)]
      end
    end
  end

  @doc """
  Returns the periods for a certain date range.

  The periods need to be sorted (by the `starts_on` date) before calling
  this function.
  """
  def find_periods_for_date_range(periods, start_date, end_date) do
    periods
    |> Enum.drop_while(&(Date.compare(&1.ends_on, start_date) == :lt))
    |> Enum.take_while(&(Date.compare(&1.starts_on, end_date) != :gt))
  end

  @doc """
  Returns the first period after a certain date (the default date is today).

  The periods need to be sorted (by the `starts_on` date) before calling
  this function.
  """
  def next_periods(periods, today \\ DateHelpers.today_berlin(), number) do
    periods
    |> Enum.drop_while(&(Date.compare(&1.ends_on, today) == :lt))
    |> Enum.take(number)
  end

  @doc """
  Returns the most recently ended period.
  """
  def find_most_recent_period(periods, today \\ DateHelpers.today_berlin()) do
    periods
    |> Enum.sort(&(Date.compare(&1.starts_on, &2.starts_on) == :lt))
    |> Enum.take_while(&(Date.compare(&1.ends_on, today) == :lt))
    |> List.last()
  end
end
