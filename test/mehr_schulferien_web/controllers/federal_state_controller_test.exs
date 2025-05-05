defmodule MehrSchulferienWeb.FederalStateControllerTest do
  use MehrSchulferienWeb.ConnCase

  setup %{conn: conn} do
    country = insert(:country, %{slug: "deutschland"})
    federal_state = insert(:federal_state, %{slug: "bayern", parent_location_id: country.id})

    {:ok, %{conn: conn, country: country, federal_state: federal_state}}
  end

  test "GET /ferien/:country_slug/bundesland/:federal_state_slug redirects to year-specific path",
       %{
         conn: conn,
         country: country,
         federal_state: federal_state
       } do
    conn = get(conn, "/ferien/#{country.slug}/bundesland/#{federal_state.slug}")

    # Get the current year
    current_year = MehrSchulferien.Calendars.DateHelpers.today_berlin().year

    # Assert that the request is redirected (302 status code)
    assert redirected_to(conn, 302) =~
             "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/#{current_year}"
  end
end
