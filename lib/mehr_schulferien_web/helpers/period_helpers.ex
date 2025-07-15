defmodule MehrSchulferienWeb.Helpers.PeriodHelpers do
  @moduledoc """
  Common period filtering and manipulation helpers to avoid duplication.
  """

  alias MehrSchulferien.Helpers.DateComparison

  @doc """
  Filter periods that are active on a specific date.
  A period is active on a date if the date falls between starts_on and ends_on inclusive.
  """
  def periods_active_on_date(periods, date) do
    Enum.filter(periods, fn period ->
      DateComparison.is_on_or_before?(period.starts_on, date) &&
        DateComparison.is_on_or_after?(period.ends_on, date)
    end)
  end

  @doc """
  Filter periods for a specific date range.
  """
  def periods_in_range(periods, start_date, end_date) do
    Enum.filter(periods, fn period ->
      # Period overlaps with date range if:
      # - Period starts before range ends AND
      # - Period ends after range starts
      DateComparison.ranges_overlap?(
        period.starts_on,
        period.ends_on,
        start_date,
        end_date
      )
    end)
  end

  @doc """
  Get school vacation periods only.
  """
  def school_vacation_periods(periods) do
    Enum.filter(periods, & &1.holiday_or_vacation_type.default_is_school_vacation)
  end

  @doc """
  Get public holiday periods only.
  """
  def public_holiday_periods(periods) do
    Enum.filter(periods, & &1.is_public_holiday)
  end

  @doc """
  Get next upcoming periods from a given date.
  """
  def next_periods_from_date(periods, date, count \\ 3) do
    periods
    |> DateComparison.filter_after(date, & &1.starts_on)
    |> Enum.sort_by(& &1.starts_on)
    |> Enum.take(count)
  end

  @doc """
  Get current period for a date (if any).
  """
  def current_period(periods, date) do
    periods
    |> periods_active_on_date(date)
    |> List.first()
  end
end
