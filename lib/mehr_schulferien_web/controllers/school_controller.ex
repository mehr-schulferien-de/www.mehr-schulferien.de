defmodule MehrSchulferienWeb.SchoolController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH

  def show(conn, %{
        "country_slug" => country_slug,
        "school_slug" => school_slug,
        "additional_categories" => _
      }) do
    redirect(conn, to: Routes.school_path(conn, :show, country_slug, school_slug))
  end

  def show(conn, %{"country_slug" => country_slug, "school_slug" => school_slug}) do
    %{country: country, federal_state: federal_state, county: county, city: city, school: school} =
      Locations.show_school_to_country_map(country_slug, school_slug)

    today = DateHelpers.today_berlin()
    location_ids = [country.id, federal_state.id, county.id, city.id, school.id]

    assigns =
      [city: city, country: country, federal_state: federal_state, school: school] ++
        CH.list_period_data(location_ids, today)

    render(conn, "show.html", assigns)
  end
end
