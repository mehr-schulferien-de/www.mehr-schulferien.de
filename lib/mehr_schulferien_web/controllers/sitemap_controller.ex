defmodule MehrSchulferienWeb.SitemapController do
  use MehrSchulferienWeb, :controller
  plug :put_layout, false

  alias MehrSchulferien.Locations

  def index(conn, _params) do
    {:ok, today_datetime} = DateTime.now("Europe/Berlin")
    today = DateTime.to_date(today_datetime)
    monday = Date.add(today, (Date.day_of_week(today) - 1) * -1)

    country = Locations.get_country_by_slug!("d")
    federal_states = Locations.list_federal_states(country)
    cities = Locations.list_cities_of_country(country)

    conn
    |> put_resp_content_type("text/xml")
    |> render("index.xml",
      country: country,
      federal_states: federal_states,
      cities: cities,
      today: today,
      monday: monday
    )
  end
end
