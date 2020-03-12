defmodule MehrSchulferienWeb.SchoolController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH

  def show(conn, %{"country_slug" => country_slug, "school_slug" => school_slug}) do
    country = Locations.get_country_by_slug!(country_slug)
    school = Locations.get_school_by_slug!(school_slug)
    city = Locations.get_location!(school.parent_location_id)
    county = Locations.get_location!(city.parent_location_id)
    federal_state = Locations.get_location!(county.parent_location_id)

    unless country.id == federal_state.parent_location_id do
      raise MehrSchulferien.CountryNotParentError
    end

    today = Date.utc_today()
    location_ids = Calendars.recursive_location_ids(school)

    assigns =
      [city: city, country: country, federal_state: federal_state, school: school] ++
        CH.show_period_data(location_ids, today)

    render(conn, "show.html", assigns)
  end
end
