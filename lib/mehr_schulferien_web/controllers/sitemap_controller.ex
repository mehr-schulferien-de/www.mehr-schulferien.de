defmodule MehrSchulferienWeb.SitemapController do
  use MehrSchulferienWeb, :controller

  plug :put_layout, false

  alias MehrSchulferien.{Calendars, Locations}
  alias MehrSchulferien.Repo
  import Ecto.Query

  def index(conn, _params) do
    today = Calendars.DateHelpers.today_berlin()
    countries = Locations.list_countries()

    # Limit data in development environment
    countries =
      if Mix.env() == :dev do
        Enum.take(countries, 20)
      else
        countries
      end

    countries = Enum.map(countries, &build_country(&1))

    conn
    |> put_resp_content_type("text/xml")
    |> render("index.xml", countries: countries, today: today)
  end

  defp build_country(country) do
    federal_states = country |> Locations.list_federal_states() |> Locations.with_periods()

    # Limit data in development environment
    federal_states = if Mix.env() == :dev, do: Enum.take(federal_states, 20), else: federal_states

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

    # Limit data in development environment
    cities = if Mix.env() == :dev, do: Enum.take(cities, 20), else: cities

    is_school_vacation_types = Calendars.list_is_school_vacation_types(country)

    # Limit data in development environment
    is_school_vacation_types =
      if Mix.env() == :dev,
        do: Enum.take(is_school_vacation_types, 20),
        else: is_school_vacation_types

    # Get all city IDs after limiting
    city_ids = Enum.map(cities, & &1.id)

    # Only get schools that belong to the cities we kept
    schools =
      country
      |> Locations.list_schools_of_country()
      |> Enum.filter(fn school -> Enum.member?(city_ids, school.parent_location_id) end)
      |> Locations.with_periods()
      |> Locations.combine_school_periods(cities)

    # Limit data in development environment
    schools = if Mix.env() == :dev, do: Enum.take(schools, 20), else: schools

    %{
      country: country,
      federal_states: federal_states,
      cities: cities,
      is_school_vacation_types: is_school_vacation_types,
      schools: schools
    }
  end
end
