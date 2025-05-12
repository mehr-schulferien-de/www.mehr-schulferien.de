defmodule MehrSchulferienWeb.SitemapController do
  use MehrSchulferienWeb, :controller

  plug :put_layout, false

  alias MehrSchulferien.{Calendars, Locations}
  alias MehrSchulferien.Repo
  import Ecto.Query

  def index(conn, _params) do
    today = Calendars.DateHelpers.today_berlin()
    countries = Enum.map(Locations.list_countries(), &build_country(&1))

    conn
    |> put_resp_content_type("text/xml")
    |> render("index.xml", countries: countries, today: today)
  end

  defp build_country(country) do
    federal_states = country |> Locations.list_federal_states() |> Locations.with_periods()

    # Get cities with at least one school in a single query
    federal_state_ids = Enum.map(federal_states, & &1.id)

    cities_with_schools_query =
      from city in MehrSchulferien.Locations.Location,
        join: county in MehrSchulferien.Locations.Location,
        on: city.parent_location_id == county.id,
        join: school in MehrSchulferien.Locations.Location,
        on: school.parent_location_id == city.id and school.is_school == true,
        where: county.parent_location_id in ^federal_state_ids and city.is_city == true,
        distinct: city.id,
        select: city

    cities = Repo.all(cities_with_schools_query) |> Locations.with_periods()

    is_school_vacation_types = Calendars.list_is_school_vacation_types(country)

    schools =
      country
      |> Locations.list_schools_of_country()
      |> Locations.with_periods()
      |> Locations.combine_school_periods(cities)

    %{
      country: country,
      federal_states: federal_states,
      cities: cities,
      is_school_vacation_types: is_school_vacation_types,
      schools: schools
    }
  end
end
