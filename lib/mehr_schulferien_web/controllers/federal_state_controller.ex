defmodule MehrSchulferienWeb.FederalStateController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars, Calendars.DateHelpers, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH

  @digits ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

  def show_holiday_or_vacation_type(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "holiday_or_vacation_type_slug" => holiday_or_vacation_type_slug
      }) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)

    holiday_or_vacation_type =
      Calendars.get_holiday_or_vacation_type_by_slug!(holiday_or_vacation_type_slug)

    today = DateHelpers.today_berlin()
    location_ids = [country.id, federal_state.id]

    assigns =
      [
        country: country,
        federal_state: federal_state,
        holiday_or_vacation_type: holiday_or_vacation_type
      ] ++
        CH.list_period_data(location_ids, today)

    render(conn, "show_holiday_or_vacation_type.html", assigns)
  end

  def show(_conn, %{"modus" => _}) do
    raise MehrSchulferien.InvalidQueryParamsError
  end

  def show(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => <<first::binary-size(1)>> <> _ = id
      })
      when first in @digits do
    location = Locations.get_federal_state!(id)
    redirect(conn, to: Routes.federal_state_path(conn, :show, country_slug, location.slug))
  end

  def show(conn, %{"country_slug" => country_slug, "federal_state_slug" => federal_state_slug}) do
    today = DateHelpers.today_berlin()
    current_year = today.year

    redirect(conn,
      to:
        Routes.federal_state_path(
          conn,
          :show_year,
          country_slug,
          federal_state_slug,
          current_year
        )
    )
  end

  def show_year(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    {federal_state, country} =
      Locations.get_federal_state_and_country_by_slug!(country_slug, federal_state_slug)

    # Convert year to integer
    year = String.to_integer(year)

    # Get current year for reference
    current_year = Date.utc_today().year

    # Define the range of years to check (current year and 3 years in each direction)
    check_years = (year - 3)..(year + 3) |> Enum.to_list()

    # Get vacation periods for the entire range with a single query
    range_start = Date.from_erl!({Enum.min(check_years), 1, 1})
    range_end = Date.from_erl!({Enum.max(check_years), 12, 31})
    location_ids = [country.id, federal_state.id]

    all_periods =
      MehrSchulferien.Periods.Query.list_school_vacation_periods(
        location_ids,
        range_start,
        range_end
      )

    # Group periods by year
    periods_by_year =
      Enum.group_by(all_periods, fn period ->
        period.starts_on.year
      end)

    # Determine which years have data
    years_with_data =
      Enum.filter(check_years, fn check_year ->
        case Map.get(periods_by_year, check_year) do
          nil -> false
          periods -> length(periods) > 0
        end
      end)
      |> Enum.sort()

    # Get just the periods for the current year
    current_year_periods = Map.get(periods_by_year, year, [])

    render(conn, "show_year.html", %{
      country: country,
      federal_state: federal_state,
      year: year,
      years_with_data: years_with_data,
      current_year: current_year,
      periods: current_year_periods,
      css_framework: :tailwind_new
    })
  end

  def old_show(conn, %{"country_slug" => country_slug, "federal_state_slug" => federal_state_slug}) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)
    location_ids = [country.id, federal_state.id]
    today = DateHelpers.today_berlin()
    current_year = today.year

    assigns =
      [
        country: country,
        federal_state: federal_state,
        current_year: current_year,
        today: today
      ] ++
        CH.list_period_data(location_ids, today) ++ CH.list_faq_data(location_ids, today)

    render(conn, "old_show.html", assigns)
  end

  def county_show(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)
    counties = Locations.list_counties(federal_state)

    counties_with_cities =
      Enum.reduce(counties, [], fn county, acc ->
        acc ++ [{county, Locations.list_cities(county)}]
      end)

    location_ids = [country.id, federal_state.id]
    today = DateHelpers.today_berlin()

    assigns =
      [
        counties_with_cities: counties_with_cities,
        country: country,
        federal_state: federal_state
      ] ++
        CH.list_period_data(location_ids, today) ++ CH.list_faq_data(location_ids, today)

    render(conn, "county_show.html", assigns)
  end
end
