defmodule MehrSchulferienWeb.CountyController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Periods, Locations}

  def show(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "county_slug" => county_slug
      }) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)
    county = Locations.get_county_by_slug!(county_slug, federal_state)
    location_ids = [country.id, federal_state.id, county.id]
    cities = Locations.list_cities(county)
    today = Date.utc_today()
    current_year = today.year
    next_12_months_periods = Periods.chunk_one_year_school_periods(location_ids, today)

    {next_3_years_headers, next_3_years_periods} =
      Periods.chunk_multi_year_school_periods(location_ids, current_year, 3)

    public_periods = Periods.list_multi_year_all_public_periods(location_ids, current_year, 3)

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
