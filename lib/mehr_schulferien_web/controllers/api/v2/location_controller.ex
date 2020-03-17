defmodule MehrSchulferienWeb.Api.V2.LocationController do
  use MehrSchulferienWeb, :controller

  def index(conn, _params) do
    locations = MehrSchulferien.Locations.list_locations()
    render(conn, "index.json", locations: locations)
  end

  def show(conn, %{"id" => id}) do
    location = MehrSchulferien.Locations.get_location!(id)
    render(conn, "show.json", location: location)
  end
end
