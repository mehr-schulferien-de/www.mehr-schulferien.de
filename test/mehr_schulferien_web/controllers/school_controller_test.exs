defmodule MehrSchulferienWeb.SchoolControllerTest do
  use MehrSchulferienWeb.ConnCase

  describe "read city data" do
    setup [:add_school]

    test "shows info for a specific federal state", %{
      conn: conn,
      country: country,
      school: school
    } do
      conn = get(conn, Routes.school_path(conn, :show, country.slug, school.slug))
      assert html_response(conn, 200) =~ school.name
    end

    test "returns 404 if country is not the root parent of the school", %{conn: conn, school: school} do
      assert_error_sent 404, fn ->
        get(conn, Routes.school_path(conn, :show, "ch", school.slug))
      end
    end
  end

  defp add_school(_) do
    country = insert(:country, %{slug: "d"})
    federal_state = insert(:federal_state, %{parent_location_id: country.id, slug: "berlin"})
    county = insert(:county, %{parent_location_id: federal_state.id, slug: "berlin"})
    city = insert(:city, %{parent_location_id: county.id, slug: "berlin"})
    school = insert(:school, %{parent_location_id: city.id, slug: "kopernikus-gymnasium"})
    {:ok, %{country: country, school: school}}
  end
end
