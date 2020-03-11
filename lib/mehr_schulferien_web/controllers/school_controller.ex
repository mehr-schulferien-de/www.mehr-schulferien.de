defmodule MehrSchulferienWeb.SchoolController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH

  def show(conn, %{"country_slug" => country_slug, "school_slug" => school_slug}) do
    country = Locations.get_country_by_slug!(country_slug)
    school = Locations.get_school_by_slug!(school_slug, country_slug)
    today = Date.utc_today()
    location_ids = Calendars.recursive_location_ids(school)
    assigns = [country: country, school: school] ++ CH.show_period_data(location_ids, today)
    render(conn, "show.html", assigns)
  end
end
