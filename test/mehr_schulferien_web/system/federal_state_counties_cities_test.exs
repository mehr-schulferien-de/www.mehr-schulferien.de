defmodule MehrSchulferienWeb.FederalStateCountiesCitiesSystemTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest

  import MehrSchulferien.Factory

  setup %{conn: conn} do
    {:ok, %{conn: conn}}
  end

  describe "counties and cities page" do
    test "shows counties and cities for a federal state", %{conn: conn} do
      # Create test data
      country = insert(:country, %{slug: "d", name: "Deutschland"})

      federal_state =
        insert(:federal_state, %{
          parent_location_id: country.id,
          slug: "rheinland-pfalz",
          name: "Rheinland-Pfalz"
        })

      # Create some counties in the federal state
      county1 =
        insert(:county, %{
          parent_location_id: federal_state.id,
          slug: "landkreis-mainz-bingen",
          name: "Landkreis Mainz-Bingen"
        })

      county2 =
        insert(:county, %{
          parent_location_id: federal_state.id,
          slug: "landkreis-trier-saarburg",
          name: "Landkreis Trier-Saarburg"
        })

      # Create some cities in the counties
      city1 =
        insert(:city, %{
          parent_location_id: county1.id,
          slug: "mainz",
          name: "Mainz"
        })

      city2 =
        insert(:city, %{
          parent_location_id: county2.id,
          slug: "trier",
          name: "Trier"
        })

      # Visit the counties and cities page using direct URL path
      conn =
        get(conn, "/land/#{country.slug}/bundesland/#{federal_state.slug}/landkreise-und-staedte")

      # Check that the page loaded successfully (200 status code)
      assert conn.status == 200

      # Check for the page title
      assert html_response(conn, 200) =~ "Landkreise und Städte in #{federal_state.name}"

      # Check that the counties are listed by name
      assert html_response(conn, 200) =~ county1.name
      assert html_response(conn, 200) =~ county2.name

      # Check that the cities are listed by name
      assert html_response(conn, 200) =~ city1.name
      assert html_response(conn, 200) =~ city2.name

      # Check for links to cities
      assert html_response(conn, 200) =~ "href=\"/ferien/#{country.slug}/stadt/#{city1.slug}\""
      assert html_response(conn, 200) =~ "href=\"/ferien/#{country.slug}/stadt/#{city2.slug}\""
    end
  end
end
