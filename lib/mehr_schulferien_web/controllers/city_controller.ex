defmodule MehrSchulferienWeb.CityController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH

  def show(conn, %{
        "country_slug" => country_slug,
        "city_slug" => city_slug
      }) do
    location = Locations.get_city_by_slug!(city_slug, country_slug)
    today = Date.utc_today()
    location_ids = Calendars.recursive_location_ids(location)
    assigns = [location: location] ++ CH.show_period_data(location_ids, today)
    render(conn, "show.html", assigns)
  end
end
