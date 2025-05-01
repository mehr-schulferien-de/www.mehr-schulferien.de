defmodule MehrSchulferienWeb.Controllers.Helpers.PeriodHelpers do
  @moduledoc """
  Helper functions for handling periods in controllers.

  This module contains functions used by controllers to fetch and organize 
  period data for rendering in views.
  """

  alias MehrSchulferien.{Calendars.DateHelpers, Periods}
  alias MehrSchulferien.Periods.{Query, Grouping}

  @doc """
  Returns period data for a location, including school and public periods.

  This is used to provide data for views that need to display period information.
  """
  def list_period_data(location_ids, today) do
    current_year = today.year
    {:ok, first_day} = Date.new(current_year, 1, 1)
    {:ok, last_day} = Date.new(current_year + 2, 12, 31)
    school_periods = Query.list_school_periods(location_ids, first_day, last_day)
    public_periods = Query.list_public_everybody_periods(location_ids, first_day, last_day)
    months = DateHelpers.get_months_map()

    # Group periods by year to determine which years have vacation data
    years_with_data =
      school_periods
      |> Enum.map(& &1.starts_on.year)
      |> Enum.uniq()
      |> Enum.sort()

    # Only include years that have vacation data
    years_to_show =
      Enum.filter([current_year, current_year + 1, current_year + 2], fn year ->
        Enum.member?(years_with_data, year)
      end)

    # Create days only for years with data
    days = Enum.flat_map(years_to_show, &DateHelpers.create_year/1)

    next_years =
      MehrSchulferienWeb.ViewHelpers.comma_join_with_a_final_und(
        Enum.map(years_to_show, &"#{&1}")
      )

    [
      current_year: current_year,
      days: days,
      months: months,
      next_three_years: next_years,
      school_periods: school_periods,
      public_periods: public_periods
    ]
  end

  @doc """
  Returns FAQ-related period data including information about holidays
  for yesterday, today, tomorrow, and the day after tomorrow.
  """
  def list_faq_data(location_ids, today) do
    yesterday = Date.add(today, -1)
    tomorrow = Date.add(today, 1)
    day_after_tomorrow = Date.add(today, 2)

    public_periods = Query.list_public_periods(location_ids, yesterday, day_after_tomorrow)

    school_free_periods =
      Query.list_school_free_periods(location_ids, yesterday, day_after_tomorrow)

    yesterdays_public_holiday_periods = Periods.find_all_periods(public_periods, yesterday)
    todays_public_holiday_periods = Periods.find_all_periods(public_periods, today)
    tomorrows_public_holiday_periods = Periods.find_all_periods(public_periods, tomorrow)

    day_after_tomorrows_public_holiday_periods =
      Periods.find_all_periods(public_periods, day_after_tomorrow)

    yesterdays_school_free_periods = Periods.find_all_periods(school_free_periods, yesterday)
    todays_school_free_periods = Periods.find_all_periods(school_free_periods, today)
    tomorrows_school_free_periods = Periods.find_all_periods(school_free_periods, tomorrow)

    day_after_tomorrows_school_free_periods =
      Periods.find_all_periods(school_free_periods, day_after_tomorrow)

    [
      day_after_tomorrow: day_after_tomorrow,
      day_after_tomorrows_public_holiday_periods: day_after_tomorrows_public_holiday_periods,
      day_after_tomorrows_school_free_periods: day_after_tomorrows_school_free_periods,
      today: today,
      todays_public_holiday_periods: todays_public_holiday_periods,
      todays_school_free_periods: todays_school_free_periods,
      tomorrow: tomorrow,
      tomorrows_public_holiday_periods: tomorrows_public_holiday_periods,
      tomorrows_school_free_periods: tomorrows_school_free_periods,
      yesterday: yesterday,
      yesterdays_public_holiday_periods: yesterdays_public_holiday_periods,
      yesterdays_school_free_periods: yesterdays_school_free_periods
    ]
  end

  @doc """
  Lists bridge day data for a given location and date range.
  """
  def list_bridge_day_data(location_ids, start_date, end_date) do
    public_periods = Query.list_public_everybody_periods(location_ids, start_date, end_date)
    bridge_day_map = Grouping.group_by_interval(public_periods)

    bridge_day_proposal_count =
      for num <- 2..5 do
        if bridge_day_map[num] do
          Enum.count(bridge_day_map[num])
        end
      end
      |> Enum.filter(&(!is_nil(&1)))
      |> Enum.sum()

    [
      bridge_day_map: bridge_day_map,
      bridge_day_proposal_count: bridge_day_proposal_count,
      public_periods: public_periods
    ]
  end

  @doc """
  Checks if a location has bridge days for a specific year.
  """
  def has_bridge_days?(location_ids, year) do
    {:ok, start_date} = Date.new(year, 1, 1)
    {:ok, end_date} = Date.new(year, 12, 31)
    public_periods = Query.list_public_everybody_periods(location_ids, start_date, end_date)
    bridge_day_map = Grouping.group_by_interval(public_periods)

    Enum.any?(2..5, fn num ->
      if bridge_day_map[num], do: Enum.count(bridge_day_map[num]) > 0, else: false
    end)
  end

  @doc """
  Validates that a year string is a valid year for bridge days.
  Returns {:ok, year} if valid, or {:error, :invalid_year} if not.
  """
  def check_year(year) do
    case Integer.parse(year) do
      {year, ""} ->
        today = DateHelpers.today_berlin()
        current_year = today.year

        if year in [current_year, current_year + 1, current_year + 2] do
          {:ok, year}
        else
          {:error, :invalid_year}
        end

      _ ->
        {:error, :invalid_year}
    end
  end
end
