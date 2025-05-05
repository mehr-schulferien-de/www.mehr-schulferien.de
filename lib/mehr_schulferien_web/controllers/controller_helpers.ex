defmodule MehrSchulferienWeb.ControllerHelpers do
  @moduledoc """
  Helper functions for use with controllers.
  """

  alias MehrSchulferien.{Calendars.DateHelpers, Periods}

  def list_period_data(location_ids, today) do
    current_year = today.year
    {:ok, first_day} = Date.new(current_year, 1, 1)
    {:ok, last_day} = Date.new(current_year + 2, 12, 31)
    school_periods = Periods.list_school_vacation_periods(location_ids, first_day, last_day)
    public_periods = Periods.list_public_everybody_periods(location_ids, first_day, last_day)
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

  def list_faq_data(location_ids, today) do
    yesterday = Date.add(today, -1)
    tomorrow = Date.add(today, 1)
    day_after_tomorrow = Date.add(today, 2)

    public_periods = Periods.list_public_periods(location_ids, yesterday, day_after_tomorrow)

    school_free_periods =
      Periods.list_school_free_periods(location_ids, yesterday, day_after_tomorrow)

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
end
