defmodule MehrSchulferienWeb.Api.CountryController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.Country

  action_fallback MehrSchulferienWeb.FallbackController

  def index(conn, _params) do
    countries = Locations.list_countries()
    render(conn, "index.json", countries: countries)
  end

  def show(conn, %{"id" => id}) do
    country = Locations.get_country!(id)
    render(conn, "show.json", country: country)
  end

end
