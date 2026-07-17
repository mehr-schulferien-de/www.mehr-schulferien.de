defmodule MehrSchulferienWeb.BridgeDayImageControllerTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  @current_year Date.utc_today().year

  setup do
    MehrSchulferien.Cache.clear_query_cache()
    country = get_or_create_deutschland()

    federal_state =
      insert(:federal_state,
        parent_location_id: country.id,
        slug: "brandenburg",
        name: "Brandenburg"
      )

    # Creates public holiday periods that qualify as bridge days
    add_public_periods(%{location: federal_state})

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
        "/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}/#{@current_year}/handwritten.svg"
      )

    assert response(conn, 200) =~ "<svg"
    assert hd(get_resp_header(conn, "content-type")) =~ "image/svg+xml"
  end

  test "GET handwritten.svg returns 404 for an invalid year", %{
    conn: conn,
    country: country,
    federal_state: federal_state
  } do
    conn =
      get(
        conn,
        "/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}/foobar/handwritten.svg"
      )

    assert response(conn, 404) == "Not found"
  end
end
