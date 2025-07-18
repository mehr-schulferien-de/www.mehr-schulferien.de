defmodule MehrSchulferienWeb.System.LocationHistoryTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest
  
  alias MehrSchulferien.Factory

  describe "location history tracking" do
    setup do
      # Create test data
      country = Factory.insert(:country, name: "Deutschland", slug: "d")
      federal_state = Factory.insert(:federal_state, 
        name: "Bayern", 
        slug: "bayern",
        parent_location_id: country.id
      )
      county = Factory.insert(:county,
        name: "München",
        slug: "muenchen-county",
        parent_location_id: federal_state.id
      )
      city = Factory.insert(:city,
        name: "München",
        slug: "muenchen",
        parent_location_id: county.id
      )
      school = Factory.insert(:school,
        name: "Test Grundschule",
        slug: "test-grundschule",
        parent_location_id: city.id
      )

      # Create some vacation periods for the pages to display
      today = Date.utc_today()
      Factory.insert(:period,
        location: federal_state,
        starts_on: Date.add(today, 30),
        ends_on: Date.add(today, 45),
        is_school_vacation: true,
        holiday_or_vacation_type: Factory.insert(:vacation_type, name: "Sommerferien")
      )

      {:ok, %{
        country: country,
        federal_state: federal_state,
        county: county,
        city: city,
        school: school
      }}
    end

    test "federal state visit tracking", %{conn: conn, federal_state: federal_state} do
      # Visit federal state page
      conn = get(conn, ~p"/ferien/d/bundesland/#{federal_state.slug}/#{Date.utc_today().year}")
      assert html_response(conn, 200)
      
      # Check that tracking script is present
      response = html_response(conn, 200)
      assert response =~ "window.LocationHistory.trackFederalStateVisit"
      assert response =~ "id: #{federal_state.id}"
      assert response =~ "slug: \"#{federal_state.slug}\""
      assert response =~ "name: \"#{federal_state.name}\""
    end

    test "city visit tracking", %{conn: conn, city: city, federal_state: federal_state} do
      # Visit city page
      conn = get(conn, ~p"/ferien/d/stadt/#{city.slug}")
      assert html_response(conn, 200)
      
      # Check that tracking script is present
      response = html_response(conn, 200)
      assert response =~ "window.LocationHistory.trackCityVisit"
      assert response =~ "id: #{city.id}"
      assert response =~ "slug: \"#{city.slug}\""
      assert response =~ "name: \"#{city.name}\""
      assert response =~ "federalStateId: #{federal_state.id}"
    end

    test "school visit tracking", %{conn: conn, school: school, city: city, federal_state: federal_state} do
      # Visit school page
      conn = get(conn, ~p"/ferien/d/schule/#{school.slug}")
      assert html_response(conn, 200)
      
      # Check that tracking script is present
      response = html_response(conn, 200)
      assert response =~ "window.LocationHistory.trackSchoolVisit"
      assert response =~ "id: #{school.id}"
      assert response =~ "slug: \"#{school.slug}\""
      assert response =~ "name: \"#{school.name}\""
      assert response =~ "cityId: #{city.id}"
      assert response =~ "federalStateId: #{federal_state.id}"
    end

    test "home page shows recent locations when cookies are present", %{conn: conn} do
      # Simulate cookies being set
      conn = conn
        |> put_req_header("cookie", 
          "recent_federal_state=%7B%22id%22%3A123%2C%22slug%22%3A%22bayern%22%2C%22name%22%3A%22Bayern%22%7D; " <>
          "recent_cities=%5B%7B%22id%22%3A456%2C%22slug%22%3A%22muenchen%22%2C%22name%22%3A%22M%C3%BCnchen%22%7D%5D; " <>
          "recent_schools=%5B%7B%22id%22%3A789%2C%22slug%22%3A%22test-schule%22%2C%22name%22%3A%22Test%20Schule%22%2C%22cityName%22%3A%22M%C3%BCnchen%22%7D%5D"
        )
      
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Check that recent locations section is displayed
      assert response =~ "Zuletzt besuchte Orte"
      assert response =~ "Bundesland:"
      assert response =~ "Bayern"
      assert response =~ "Städte:"
      assert response =~ "München"
      assert response =~ "Schulen:"
      assert response =~ "Test Schule"
    end

    test "home page does not show recent locations section without cookies", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Recent locations section should not be present
      refute response =~ "Zuletzt besuchte Orte"
    end

    test "cookie helper correctly parses location cookies", %{conn: conn} do
      # Test with properly formatted cookies
      conn = conn
        |> put_req_header("cookie", 
          "recent_federal_state=%7B%22id%22%3A123%2C%22slug%22%3A%22bayern%22%2C%22name%22%3A%22Bayern%22%7D"
        )
      
      alias MehrSchulferienWeb.Helpers.CookieHelpers
      
      recent_state = CookieHelpers.get_recent_federal_state(conn)
      assert recent_state == %{id: 123, slug: "bayern", name: "Bayern"}
    end

    test "javascript assets include location history module", %{conn: conn} do
      # Check that the JavaScript file exists and is being served
      conn = get(conn, ~p"/assets/app.js")
      assert response(conn, 200)
      
      # The response should include our LocationHistory module
      response_body = response(conn, 200)
      assert response_body =~ "LocationHistory"
    end
  end
end