defmodule MehrSchulferienWeb.FederalStateCountiesCitiesSystemTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest

  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  setup %{conn: conn} do
    {:ok, %{conn: conn}}
  end

  describe "counties and cities page" do
    test "shows counties and cities for a federal state", %{conn: conn} do
      # Create test data
      country = get_or_create_deutschland()

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

      insert(:school, %{parent_location_id: city1.id, name: "Test School Mainz"})

      city2 =
        insert(:city, %{
          parent_location_id: county2.id,
          slug: "trier",
          name: "Trier"
        })

      insert(:school, %{parent_location_id: city2.id, name: "Test School Trier"})

      # Visit the counties and cities page using direct URL path
      conn =
        get(
          conn,
          "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/landkreise-und-staedte"
        )

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

      # Check that the links to the cities are correct
      assert html_response(conn, 200) =~
               "href=\"#{~p"/ferien/#{country.slug}/stadt/#{city1.slug}"}\""

      assert html_response(conn, 200) =~
               "href=\"#{~p"/ferien/#{country.slug}/stadt/#{city2.slug}"}\""
    end

    test "sorts counties and cities alphabetically", %{conn: conn} do
      # Create test data
      country = get_or_create_deutschland()

      federal_state =
        insert(:federal_state, %{
          parent_location_id: country.id,
          slug: "test-state",
          name: "Test State"
        })

      # Create counties in non-alphabetical order
      county_z =
        insert(:county, %{
          parent_location_id: federal_state.id,
          slug: "z-county",
          name: "Z County"
        })

      county_a =
        insert(:county, %{
          parent_location_id: federal_state.id,
          slug: "a-county",
          name: "A County"
        })

      county_m =
        insert(:county, %{
          parent_location_id: federal_state.id,
          slug: "m-county",
          name: "M County"
        })

      # Create cities in non-alphabetical order for county A
      city_z =
        insert(:city, %{
          parent_location_id: county_a.id,
          slug: "z-city",
          name: "Z City"
        })

      insert(:school, %{parent_location_id: city_z.id, name: "School Z"})

      city_a =
        insert(:city, %{
          parent_location_id: county_a.id,
          slug: "a-city",
          name: "A City"
        })

      insert(:school, %{parent_location_id: city_a.id, name: "School A"})

      city_m =
        insert(:city, %{
          parent_location_id: county_a.id,
          slug: "m-city",
          name: "M City"
        })

      insert(:school, %{parent_location_id: city_m.id, name: "School M"})

      # Add cities with schools to other counties so they appear
      city_in_m =
        insert(:city, %{
          parent_location_id: county_m.id,
          slug: "city-in-m",
          name: "City in M"
        })

      insert(:school, %{parent_location_id: city_in_m.id, name: "School in M"})

      city_in_z =
        insert(:city, %{
          parent_location_id: county_z.id,
          slug: "city-in-z",
          name: "City in Z"
        })

      insert(:school, %{parent_location_id: city_in_z.id, name: "School in Z"})

      # Visit the counties and cities page
      conn =
        get(
          conn,
          "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/landkreise-und-staedte"
        )

      # Get the HTML response
      html = html_response(conn, 200)

      # Check that counties appear in alphabetical order
      # Find the main content div first to avoid false matches in navigation
      main_content_start = String.split(html, "Landkreise und Städte in") |> List.last()

      # Using regex to check the order of appearance
      {a_pos, _} = :binary.match(main_content_start, "A County")
      {m_pos, _} = :binary.match(main_content_start, "M County")
      {z_pos, _} = :binary.match(main_content_start, "Z County")

      assert a_pos < m_pos
      assert m_pos < z_pos

      # Check that cities within a county appear in alphabetical order
      # Since all three test cities are in A County, they should appear in order: A City, M City, Z City
      {a_city_pos, _} = :binary.match(main_content_start, "A City")
      {m_city_pos, _} = :binary.match(main_content_start, "M City")
      {z_city_pos, _} = :binary.match(main_content_start, "Z City")

      assert a_city_pos < m_city_pos
      assert m_city_pos < z_city_pos
    end
  end
end
