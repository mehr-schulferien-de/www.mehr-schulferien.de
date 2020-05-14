defmodule MehrSchulferienWeb.PageControllerTest do
  use MehrSchulferienWeb.ConnCase

  setup %{conn: conn} do
    country = insert(:country, %{slug: "d"})
    federal_states = insert_list(3, :federal_state, %{parent_location_id: country.id})

    holiday_or_vacation_type =
      insert(:holiday_or_vacation_type, %{country_location_id: country.id})

    for federal_state <- federal_states do
      MehrSchulferien.Calendars.create_period(%{
        holiday_or_vacation_type_id: holiday_or_vacation_type.id,
        location_id: federal_state.id
      })
    end

    {:ok, %{conn: conn}}
  end

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Schulferien und gesetzliche Feiertage für Deutschland"
  end

  test "custom meta tags are generated", %{conn: conn} do
    conn = get(conn, "/")

    assert html_response(conn, 200) =~
             "Alle Ferientermine für"
  end
end
