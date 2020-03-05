defmodule MehrSchulferienWeb.FederalStateController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars, Calendars.DateHelpers, Display}

  @digits ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

  def show(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => <<first::binary-size(1)>> <> _ = id
      })
      when first in @digits do
    location = Display.get_federal_state!(id)
    redirect(conn, to: Routes.federal_state_path(conn, :show, country_slug, location.slug))
  end

  def show(conn, %{"country_slug" => country_slug, "federal_state_slug" => federal_state_slug}) do
    location = Display.get_federal_state_by_slug!(country_slug, federal_state_slug)
    today = Date.utc_today()
    current_year = today.year
    location_ids = Calendars.recursive_location_ids(location)

    next_12_months_periods = Display.get_12_months_periods(location_ids, today)

    {next_3_years_headers, next_3_years_periods} =
      Display.get_3_years_periods(location_ids, current_year)

    public_periods = Display.get_3_years_public_periods(location_ids, current_year)

    public_periods =
      Enum.filter(public_periods, &(&1.holiday_or_vacation_type.name != "Wochenende"))

    days = DateHelpers.create_3_years(current_year)
    months = DateHelpers.get_months_map()
    next_three_years = Enum.join([current_year, current_year + 1, current_year + 2], ", ")

    render(conn, "show.html",
      current_year: current_year,
      days: days,
      location: location,
      months: months,
      next_12_months_periods: next_12_months_periods,
      next_3_years_headers: next_3_years_headers,
      next_3_years_periods: next_3_years_periods,
      next_three_years: next_three_years,
      public_periods: public_periods
    )
  end

  def faq(conn, %{"country_slug" => country_slug, "federal_state_slug" => federal_state_slug}) do
    location = Display.get_federal_state_by_slug!(country_slug, federal_state_slug)
    location_ids = Calendars.recursive_location_ids(location)
    today = Date.utc_today()
    todays_public_holiday_periods = Display.list_public_holiday_periods(location_ids, today)

    tomorrows_public_holiday_periods =
      Display.list_public_holiday_periods(location_ids, Date.add(today, 1))

    day_after_tomorrows_public_holiday_periods =
      Display.list_public_holiday_periods(location_ids, Date.add(today, 2))

    todays_school_free_periods = Display.list_school_free_periods(location_ids, today)

    tomorrows_school_free_periods =
      Display.list_school_free_periods(location_ids, Date.add(today, 1))

    day_after_tomorrows_school_free_periods =
      Display.list_school_free_periods(location_ids, Date.add(today, 2))

    render(conn, "faq.html",
      location: location,
      today: today,
      todays_public_holiday_periods: todays_public_holiday_periods,
      tomorrows_public_holiday_periods: tomorrows_public_holiday_periods,
      day_after_tomorrows_public_holiday_periods: day_after_tomorrows_public_holiday_periods,
      todays_school_free_periods: todays_school_free_periods,
      tomorrows_school_free_periods: tomorrows_school_free_periods,
      day_after_tomorrows_school_free_periods: day_after_tomorrows_school_free_periods
    )
  end
end
