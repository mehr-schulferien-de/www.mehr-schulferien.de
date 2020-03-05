defmodule MehrSchulferienWeb.CountyControllerTest do
  use MehrSchulferienWeb.ConnCase

  describe "read county data" do
    setup [:add_county]

    test "shows info for a specific federal state", %{
      conn: conn,
      county: county,
      country: country,
      federal_state: federal_state
    } do
      conn =
        get(conn, Routes.county_path(conn, :show, country.slug, federal_state.slug, county.slug))

      assert html_response(conn, 200) =~ county.name
    end
  end

  defp add_county(_) do
    country = insert(:country, %{slug: "d"})
    federal_state = insert(:federal_state, %{parent_location_id: country.id, slug: "berlin"})
    county = insert(:county, %{parent_location_id: federal_state.id, slug: "berlin"})
    {:ok, %{county: county, country: country, federal_state: federal_state}}
  end
end
