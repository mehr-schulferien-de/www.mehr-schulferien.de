defmodule MehrSchulferienWeb.VacationImageControllerTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  setup do
    MehrSchulferien.Cache.clear_query_cache()
    country = get_or_create_deutschland()

    federal_state =
      insert(:federal_state,
        parent_location_id: country.id,
        slug: "niedersachsen",
        name: "Niedersachsen"
      )

    vacation_type =
      insert(:holiday_or_vacation_type,
        slug: "oster",
        name: "Ostern",
        colloquial: "Osterferien",
        default_is_school_vacation: true,
        country_location_id: country.id
      )

    insert(:period,
      location_id: federal_state.id,
      holiday_or_vacation_type_id: vacation_type.id,
      starts_on: ~D[2024-03-25],
      ends_on: ~D[2024-04-05],
      is_school_vacation: true,
      is_valid_for_students: true
    )

    {:ok, federal_state: federal_state}
  end

  test "GET handwritten.svg returns 200 with SVG content type", %{
    conn: conn,
    federal_state: federal_state
  } do
    conn = get(conn, "/osterferien/#{federal_state.slug}/2024/handwritten.svg")

    assert response(conn, 200) =~ "<svg"
    assert hd(get_resp_header(conn, "content-type")) =~ "image/svg+xml"
  end

  test "GET handwritten.svg returns 404 for an unknown vacation type", %{
    conn: conn,
    federal_state: federal_state
  } do
    conn = get(conn, "/fantasieferien/#{federal_state.slug}/2024/handwritten.svg")

    assert response(conn, 404) == "Not found"
  end
end
