defmodule MehrSchulferienWeb.FederalStateImageControllerTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  setup do
    MehrSchulferien.Cache.clear_query_cache()
    country = get_or_create_deutschland()

    federal_state =
      insert(:federal_state,
        parent_location_id: country.id,
        slug: "bayern",
        name: "Bayern"
      )

    vacation_type =
      insert(:holiday_or_vacation_type,
        slug: "sommer",
        name: "Sommer",
        colloquial: "Sommerferien",
        default_is_school_vacation: true,
        country_location_id: country.id
      )

    # Multi-day vacation period (single-day periods are filtered out)
    insert(:period,
      location_id: federal_state.id,
      holiday_or_vacation_type_id: vacation_type.id,
      starts_on: ~D[2024-08-01],
      ends_on: ~D[2024-09-09],
      is_school_vacation: true,
      is_valid_for_students: true
    )

    {:ok, country: country, federal_state: federal_state}
  end

  test "GET handwritten.svg returns 200 with SVG content type", %{
    conn: conn,
    country: country,
    federal_state: federal_state
  } do
    conn =
      get(
        conn,
        "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/2024/handwritten.svg"
      )

    assert response(conn, 200) =~ "<svg"
    assert hd(get_resp_header(conn, "content-type")) =~ "image/svg+xml"
  end

  test "GET handwritten.svg returns 404 when there are no vacation periods", %{
    conn: conn,
    country: country,
    federal_state: federal_state
  } do
    conn =
      get(
        conn,
        "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/2019/handwritten.svg"
      )

    assert response(conn, 404) == "No vacation periods found"
  end
end
