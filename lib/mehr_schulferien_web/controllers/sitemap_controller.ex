defmodule MehrSchulferienWeb.SitemapController do
  use MehrSchulferienWeb, :controller

  plug :put_layout, false

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Calendars

  def index(conn, _params) do
    {:ok, today_datetime} = DateTime.now("Europe/Berlin")
    today = DateTime.to_date(today_datetime)

    country = Locations.get_country_by_slug!("d")
    federal_states = country |> Locations.list_federal_states() |> Locations.with_periods()
    cities = Locations.list_cities_of_country(country)
    is_school_vacation_types = Calendars.list_is_school_vacation_types(country)
    schools = Locations.list_schools_of_country(country)

    conn
    |> put_resp_content_type("text/xml")
    |> render("index.xml",
      country: country,
      federal_states: federal_states,
      cities: cities,
      today: today,
      is_school_vacation_types: is_school_vacation_types,
      schools: schools
    )
  end
end
