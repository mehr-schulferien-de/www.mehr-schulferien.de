defmodule MehrSchulferienWeb.CityController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.ViewHelpers
  import MehrSchulferienWeb.LocationTrackingHelpers

  def show_year(conn, %{
        "country_slug" => country_slug,
        "city_slug" => city_slug,
        "year" => _year
      }) do
    %{country: country} =
      Locations.show_city_to_country_map(country_slug, city_slug)

    # Redirect to the city page without year (301 permanent redirect for SEO)
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: ~p"/ferien/#{country.slug}/stadt/#{city_slug}")
  end

  def show(conn, %{"country_slug" => country_slug, "city_slug" => city_slug}) do
    %{country: country, federal_state: federal_state, county: county, city: city} =
      Locations.show_city_to_country_map(country_slug, city_slug)

    # Get schools in this city for display
    schools = Locations.list_schools(city)

    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year
    next_year = current_year + 1
    location_ids = [country.id, federal_state.id, county.id, city.id]

    # Fetch data for current year and next year
    current_year_data = CH.prepare_show_year_data(location_ids, current_year, today)
    next_year_data = CH.prepare_show_year_data(location_ids, next_year, today)

    # Combine periods from both years
    all_periods = current_year_data.periods ++ next_year_data.periods
    all_public_periods = current_year_data.public_periods ++ next_year_data.public_periods

    # Calculate adjoining_duration for each period
    periods_with_duration =
      Enum.map(all_periods, fn period ->
        days = Date.diff(period.ends_on, period.starts_on) + 1

        effective_duration =
          ViewHelpers.calculate_effective_duration(period, all_periods ++ all_public_periods)

        difference = effective_duration - days
        Map.put(period, :adjoining_duration, difference)
      end)

    # Always return 200 status for city pages
    conn = conn

    # Track city visit
    conn = track_location_visit(conn, "c", city.slug)

    render(
      conn,
      "show.html",
      %{
        country: country,
        federal_state: federal_state,
        county: county,
        city: city,
        schools: schools,
        css_framework: :tailwind_new,
        periods: periods_with_duration,
        public_periods: all_public_periods,
        all_periods: all_periods ++ all_public_periods,
        current_year: current_year,
        next_year: next_year,
        years_with_data: current_year_data.years_with_data,
        today: today,
        has_data: current_year_data.has_data or next_year_data.has_data
      }
      |> Map.merge(Map.new(current_year_data.faq_data))
    )
  end
end
