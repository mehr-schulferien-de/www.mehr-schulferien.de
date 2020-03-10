defmodule MehrSchulferienWeb.CountyController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Locations
  alias MehrSchulferienWeb.ControllerHelpers, as: CH

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

    assigns =
      [cities: cities, country_slug: country_slug, location: county] ++
        CH.show_period_data(location_ids, today)

    render(conn, "show.html", assigns)
  end
end
