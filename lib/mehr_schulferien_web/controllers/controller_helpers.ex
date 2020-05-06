defmodule MehrSchulferienWeb.ControllerHelpers do
  @moduledoc """
  Helper functions for use with controllers.
  """

  alias MehrSchulferien.{Calendars.DateHelpers, Periods}

  def show_period_data(location_ids, today) do
    current_year = today.year
    {:ok, first_day} = Date.new(current_year, 1, 1)
    {:ok, last_day} = Date.new(current_year + 2, 12, 31)
    school_periods = Periods.list_school_periods(location_ids, first_day, last_day)
    public_periods = Periods.list_public_periods(location_ids, first_day, last_day)
    days = DateHelpers.create_3_years(current_year)
    months = DateHelpers.get_months_map()

    next_three_years =
      MehrSchulferienWeb.ViewHelpers.comma_join_with_a_final_und([
        "#{current_year}",
        "#{current_year + 1}",
        "#{current_year + 2}"
      ])

    [
      current_year: current_year,
      days: days,
      months: months,
      next_three_years: next_three_years,
      school_periods: school_periods,
      public_periods: public_periods
    ]
  end

  def faq_data(location_ids, today) do
    todays_public_holiday_periods = Periods.list_public_holiday_periods(location_ids, today)

    yesterdays_public_holiday_periods =
      Periods.list_public_holiday_periods(location_ids, Date.add(today, -1))

    tomorrows_public_holiday_periods =
      Periods.list_public_holiday_periods(location_ids, Date.add(today, 1))

    day_after_tomorrows_public_holiday_periods =
      Periods.list_public_holiday_periods(location_ids, Date.add(today, 2))

    todays_school_free_periods = Periods.list_school_free_periods(location_ids, today)

    tomorrows_school_free_periods =
      Periods.list_school_free_periods(location_ids, Date.add(today, 1))

    day_after_tomorrows_school_free_periods =
      Periods.list_school_free_periods(location_ids, Date.add(today, 2))

    [
      today: today,
      todays_public_holiday_periods: todays_public_holiday_periods,
      yesterdays_public_holiday_periods: yesterdays_public_holiday_periods,
      tomorrows_public_holiday_periods: tomorrows_public_holiday_periods,
      day_after_tomorrows_public_holiday_periods: day_after_tomorrows_public_holiday_periods,
      todays_school_free_periods: todays_school_free_periods,
      tomorrows_school_free_periods: tomorrows_school_free_periods,
      day_after_tomorrows_school_free_periods: day_after_tomorrows_school_free_periods
    ]
  end
end
