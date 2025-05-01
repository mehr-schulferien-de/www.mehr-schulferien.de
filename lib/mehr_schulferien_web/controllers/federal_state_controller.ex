defmodule MehrSchulferienWeb.FederalStateController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars, Calendars.DateHelpers, Locations}
  alias MehrSchulferienWeb.Controllers.Helpers.{LocationHelpers, PeriodHelpers}

  @digits ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

  def show_holiday_or_vacation_type(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "holiday_or_vacation_type_slug" => holiday_or_vacation_type_slug
      }) do
    {country, federal_state, location_ids} =
      LocationHelpers.get_locations_and_ids(country_slug, federal_state_slug)

    holiday_or_vacation_type =
      Calendars.get_holiday_or_vacation_type_by_slug!(holiday_or_vacation_type_slug)

    today = DateHelpers.today_berlin()

    assigns =
      [
        country: country,
        federal_state: federal_state,
        holiday_or_vacation_type: holiday_or_vacation_type
      ] ++
        PeriodHelpers.list_period_data(location_ids, today)

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
    {country, federal_state, location_ids} =
      LocationHelpers.get_locations_and_ids(country_slug, federal_state_slug)

    today = DateHelpers.today_berlin()
    current_year = today.year

    assigns =
      [
        country: country,
        federal_state: federal_state,
        current_year: current_year,
        today: today
      ] ++
        PeriodHelpers.list_period_data(location_ids, today) ++
        PeriodHelpers.list_faq_data(location_ids, today)

    render(conn, "show.html", assigns)
  end

  def county_show(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    {country, federal_state, location_ids} =
      LocationHelpers.get_locations_and_ids(country_slug, federal_state_slug)

    counties_with_cities = LocationHelpers.get_counties_with_cities(federal_state)
    today = DateHelpers.today_berlin()

    assigns =
      [
        counties_with_cities: counties_with_cities,
        country: country,
        federal_state: federal_state
      ] ++
        PeriodHelpers.list_period_data(location_ids, today) ++
        PeriodHelpers.list_faq_data(location_ids, today)

    render(conn, "county_show.html", assigns)
  end
end
