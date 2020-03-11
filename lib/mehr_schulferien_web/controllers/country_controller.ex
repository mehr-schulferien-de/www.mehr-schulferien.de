defmodule MehrSchulferienWeb.CountryController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Locations

  def show(conn, %{"country_slug" => country_slug}) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_states = Locations.list_federal_states(country)
    render(conn, "show.html", country: country, federal_states: federal_states)
  end
end
