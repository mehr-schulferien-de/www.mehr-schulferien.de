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
    _current_year = MehrSchulferien.Calendars.DateHelpers.today_berlin().year

    # Assert that the request is redirected (302 status code)
    assert redirected_to(conn, 302) =~
             "/land/#{country.slug}/bundesland/#{federal_state.slug}"
  end

  test "GET /ferien/:country_slug/bundesland/:federal_state_slug/:year returns 404 when no periods exist for the year",
       %{
         conn: conn,
         country: country,
         federal_state: federal_state
       } do
    # Use a year far in the future (2050) to ensure no periods exist
    year_without_data = 2050

    # Make the request to the show_year action for a year with no periods
    conn =
      get(conn, "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/#{year_without_data}")

    # Assert that the response has a 404 status code (redirected)
    assert conn.status == 302

    # Follow the redirect
    redirected_path = redirected_to(conn, 302)
    conn = get(recycle(conn), redirected_path)

    # Now we should get a 404
    assert conn.status == 404

    # Assert that the page still renders with the correct layout and content
    assert html_response(conn, 404) =~ federal_state.name
    assert html_response(conn, 404) =~ "#{year_without_data}"
  end
end
