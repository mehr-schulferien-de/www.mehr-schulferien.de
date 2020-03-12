defmodule MehrSchulferienWeb.CityController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH

  def show(conn, %{
        "country_slug" => country_slug,
        "city_slug" => city_slug
      }) do
    country = Locations.get_country_by_slug!(country_slug)
    city = Locations.get_city_by_slug!(city_slug)
    county = Locations.get_location!(city.parent_location_id)
    federal_state = Locations.get_location!(county.parent_location_id)

    unless country.id == federal_state.parent_location_id do
      raise MehrSchulferien.CountryNotParentError
    end

    today = Date.utc_today()
    location_ids = Calendars.recursive_location_ids(city)

    assigns =
      [city: city, country: country, federal_state: federal_state] ++
        CH.show_period_data(location_ids, today)

    render(conn, "show.html", assigns)
  end
end
