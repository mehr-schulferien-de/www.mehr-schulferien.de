defmodule MehrSchulferienWeb.CityController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.ViewHelpers

  def show_year(conn, %{
        "country_slug" => country_slug,
        "city_slug" => city_slug,
        "year" => year
      }) do
    %{country: country, federal_state: federal_state, county: county, city: city} =
      Locations.show_city_to_country_map(country_slug, city_slug)

    # Get schools in this city for display
    # If a city has no schools, it should return a 404
    schools = Locations.list_schools(city)
    city_has_schools = not Enum.empty?(schools)

    today = DateHelpers.get_today_or_custom_date(conn)
    location_ids = [country.id, federal_state.id, county.id, city.id]

    # Use shared logic to prepare show_year data
    data = CH.prepare_show_year_data(location_ids, year, today)

    # Calculate adjoining_duration for each period
    # This ensures display values reflect the current calculation
    periods_with_duration =
      Enum.map(data.periods, fn period ->
        days = Date.diff(period.ends_on, period.starts_on) + 1
        effective_duration = ViewHelpers.calculate_effective_duration(period, data.all_periods)
        difference = effective_duration - days
        Map.put(period, :adjoining_duration, difference)
      end)

    # Set the appropriate status code based on data availability and presence of schools
    conn =
      if city_has_schools and data.has_data do
        conn
      else
        put_status(conn, 404)
      end

    render(
      conn,
      "show_year.html",
      %{
        country: country,
        federal_state: federal_state,
        county: county,
        city: city,
        schools: schools,
        css_framework: :tailwind_new,
        periods: periods_with_duration,
        all_periods: data.all_periods
      }
      |> Map.merge(data)
      |> Map.merge(Map.new(data.faq_data))
    )
  end

  def show(conn, %{"country_slug" => country_slug, "city_slug" => city_slug}) do
    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year

    redirect(conn,
      to:
        Routes.city_path(
          conn,
          :show_year,
          country_slug,
          city_slug,
          current_year
        ),
      status: :temporary_redirect
    )
  end
end
