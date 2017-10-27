defmodule MehrSchulferienWeb.Api.CityController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.City

  action_fallback MehrSchulferienWeb.FallbackController

  def index(conn, _params) do
    cities = Locations.list_cities()
    render(conn, "index.json", cities: cities)
  end

  def show(conn, %{"id" => id}) do
    city = Locations.get_city!(id)
    render(conn, "show.json", city: city)
  end

end
