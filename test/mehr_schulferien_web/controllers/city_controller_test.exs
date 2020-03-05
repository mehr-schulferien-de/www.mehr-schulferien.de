defmodule MehrSchulferienWeb.CityControllerTest do
  use MehrSchulferienWeb.ConnCase

  describe "read city data" do
    setup [:add_city]

    test "shows info for a specific federal state", %{conn: conn, city: city, country: country} do
      conn = get(conn, Routes.city_path(conn, :show, country.slug, city.slug))
      assert html_response(conn, 200) =~ city.name
    end
  end

  defp add_city(_) do
    country = insert(:country, %{slug: "d"})
    federal_state = insert(:federal_state, %{parent_location_id: country.id, slug: "berlin"})
    county = insert(:county, %{parent_location_id: federal_state.id, slug: "berlin"})
    city = insert(:city, %{parent_location_id: county.id, slug: "berlin"})
    {:ok, %{city: city, country: country}}
  end
end
