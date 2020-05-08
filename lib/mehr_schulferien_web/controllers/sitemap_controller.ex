defmodule MehrSchulferienWeb.SitemapController do
  use MehrSchulferienWeb, :controller

  plug :put_layout, false

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Calendars

  def index(conn, _params) do
    today = Calendars.DateHelpers.today_berlin()
    countries = Enum.map(Locations.list_countries(), &build_country(&1))

    conn
    |> put_resp_content_type("text/xml")
    |> render("index.xml", countries: countries, today: today)
  end

  defp build_country(country) do
    federal_states = country |> Locations.list_federal_states() |> Locations.with_periods()
    cities = Locations.list_cities_of_country(country)
    is_school_vacation_types = Calendars.list_is_school_vacation_types(country)
    schools = Locations.list_schools_of_country(country)

    %{
      country: country,
      federal_states: federal_states,
      cities: cities,
      is_school_vacation_types: is_school_vacation_types,
      schools: schools
    }
  end
end
