defmodule MehrSchulferienWeb.FederalStateController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.ViewHelpers

  @digits ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

  def show(_conn, %{"modus" => _}) do
    raise MehrSchulferien.InvalidQueryParamsError
  end

  def show(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => <<first::binary-size(1)>> <> _ = id
      })
      when first in @digits do
    location = Locations.get_federal_state!(id)
    redirect(conn, to: Routes.federal_state_path(conn, :show, country_slug, location.slug))
  end

  def show(conn, %{"country_slug" => country_slug, "federal_state_slug" => federal_state_slug}) do
    today = DateHelpers.get_today_or_custom_date(conn)
    current_year = today.year

    redirect(conn,
      to:
        Routes.federal_state_path(
          conn,
          :show_year,
          country_slug,
          federal_state_slug,
          current_year
        ),
      status: :temporary_redirect
    )
  end

  def show_year(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    {federal_state, country} =
      Locations.get_federal_state_and_country_by_slug!(country_slug, federal_state_slug)

    # Check if year is "brueckentage" and handle special case
    if year == "brueckentage" do
      conn = Plug.Conn.put_status(conn, :not_found)
      raise Phoenix.Router.NoRouteError, conn: conn, router: MehrSchulferienWeb.Router
    end

    today = DateHelpers.get_today_or_custom_date(conn)
    location_ids = [country.id, federal_state.id]

    # Use shared logic to prepare show_year data
    data = CH.prepare_show_year_data(location_ids, year, today)

    # Calculate adjoining_duration for each period
    # This ensures display values reflect the current calculation
    periods_with_duration =
      Enum.map(data.periods, fn period ->
        days = Date.diff(period.ends_on, period.starts_on) + 1

        effective_duration =
          ViewHelpers.calculate_effective_duration(period, data.all_periods)

        difference = effective_duration - days
        Map.put(period, :adjoining_duration, difference)
      end)

    # Set the appropriate status code based on data availability
    conn = if data.has_data, do: conn, else: put_status(conn, 404)

    render(
      conn,
      "show_year.html",
      %{
        country: country,
        federal_state: federal_state,
        css_framework: :tailwind_new,
        periods: periods_with_duration,
        all_periods: data.all_periods
      }
      |> Map.merge(data)
      |> Map.merge(Map.new(data.faq_data))
    )
  end

  def county_show(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)

    # Use the optimized function to get counties with cities having schools
    counties_with_cities = Locations.list_counties_with_cities_having_schools(federal_state)

    location_ids = [country.id, federal_state.id]
    today = DateHelpers.get_today_or_custom_date(conn)

    assigns =
      [
        counties_with_cities: counties_with_cities,
        country: country,
        federal_state: federal_state,
        css_framework: :tailwind_new
      ] ++
        CH.list_period_data(location_ids, today) ++ CH.list_faq_data(location_ids, today)

    render(conn, "county_show.html", assigns)
  end
end
