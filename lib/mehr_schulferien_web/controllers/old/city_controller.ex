defmodule MehrSchulferienWeb.Old.CityController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH

  def show(conn, %{
        "country_slug" => country_slug,
        "city_slug" => city_slug
      }) do
    %{country: country, federal_state: federal_state, county: county, city: city} =
      Locations.show_city_to_country_map(country_slug, city_slug)

    today = DateHelpers.today_berlin()
    location_ids = [country.id, federal_state.id, county.id, city.id]
    schools = Locations.list_schools(city)

    city_name_equals_a_federal_state? =
      Enum.member?(["hessen", "hamburg", "bremen", "berlin", "bayern"], city.slug)

    assigns =
      [
        city: city,
        country: country,
        federal_state: federal_state,
        schools: schools,
        city_name_equals_a_federal_state?: city_name_equals_a_federal_state?
      ] ++
        CH.list_period_data(location_ids, today)

    render(conn, "show.html", assigns)
  end
end
