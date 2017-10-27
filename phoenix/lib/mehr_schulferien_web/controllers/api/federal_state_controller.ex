defmodule MehrSchulferienWeb.Api.FederalStateController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.FederalState

  action_fallback MehrSchulferienWeb.FallbackController

  def index(conn, _params) do
    federal_states = Locations.list_federal_states()
    render(conn, "index.json", federal_states: federal_states)
  end

  def show(conn, %{"id" => id}) do
    federal_state = Locations.get_federal_state!(id)
    render(conn, "show.json", federal_state: federal_state)
  end

end
