defmodule MehrSchulferienWeb.FederalStateController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Locations
  alias MehrSchulferienWeb.ControllerHelpers, as: CH

  @digits ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

  def show(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => <<first::binary-size(1)>> <> _ = id
      })
      when first in @digits do
    location = Locations.get_federal_state!(id)
    redirect(conn, to: Routes.federal_state_path(conn, :show, country_slug, location.slug))
  end

  def show(conn, %{"country_slug" => country_slug, "federal_state_slug" => federal_state_slug}) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)
    location_ids = [country.id, federal_state.id]
    today = Date.utc_today()

    assigns =
      [
        country_slug: country_slug,
        location: federal_state
      ] ++
        CH.show_period_data(location_ids, today) ++ CH.faq_data(location_ids, today)

    render(conn, "show.html", assigns)
  end

  def county_show(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)
    counties = Locations.list_counties(federal_state)

    counties_with_cities =
      Enum.reduce(counties, [], fn county, acc ->
        acc ++ [{county, Locations.list_cities(county)}]
      end)

    location_ids = [country.id, federal_state.id]
    today = Date.utc_today()

    assigns =
      [
        counties_with_cities: counties_with_cities,
        country_slug: country_slug,
        location: federal_state
      ] ++
        CH.show_period_data(location_ids, today) ++ CH.faq_data(location_ids, today)

    render(conn, "county_show.html", assigns)
  end
end
