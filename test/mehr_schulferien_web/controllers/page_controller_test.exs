defmodule MehrSchulferienWeb.PageControllerTest do
  use MehrSchulferienWeb.ConnCase

  test "GET /", %{conn: conn} do
    country = insert(:country, %{slug: "d"})
    _federal_states = insert_list(3, :federal_state, %{parent_location_id: country.id})
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Schulferien, Feiertage"
  end
end
