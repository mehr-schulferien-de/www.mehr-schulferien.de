defmodule MehrSchulferienWeb.PageControllerTest do
  use MehrSchulferienWeb.ConnCase

  setup %{conn: conn} do
    country = insert(:country, %{slug: "d"})
    _federal_states = insert_list(3, :federal_state, %{parent_location_id: country.id})
    {:ok, %{conn: conn}}
  end

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Aktuelle Schulferien und Feiertage"
  end

  test "custom meta tags are generated", %{conn: conn} do
    conn = get(conn, "/")

    assert html_response(conn, 200) =~
             "Schulferienkalender und gesetzliche Feiertage für Deutschland"
  end
end
