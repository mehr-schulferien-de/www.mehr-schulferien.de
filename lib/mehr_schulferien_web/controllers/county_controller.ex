defmodule MehrSchulferienWeb.CountyController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars, Calendars.DateHelpers, Display, Maps}

  def show(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "county_slug" => county_slug
      }) do
    county = Display.get_county_by_slug!(county_slug, federal_state_slug, country_slug)
    cities = Maps.list_cities(county)
    today = Date.utc_today()
    current_year = today.year
    location_ids = Calendars.recursive_location_ids(county)

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
      cities: cities,
      county: county,
      country_slug: country_slug,
      current_year: current_year,
      days: days,
      months: months,
      next_12_months_periods: next_12_months_periods,
      next_3_years_headers: next_3_years_headers,
      next_3_years_periods: next_3_years_periods,
      next_three_years: next_three_years,
      public_periods: public_periods
    )
  end
end
