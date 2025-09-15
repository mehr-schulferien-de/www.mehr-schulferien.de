defmodule MehrSchulferienWeb.Api.V2.LocationControllerTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.Factory

  setup %{conn: conn} do
    # Create test locations
    country = insert(:country, %{name: "Test Country", code: "TC"})

    federal_state =
      insert(:federal_state, %{
        name: "Test State",
        code: "TS",
        parent_location_id: country.id
      })

    city =
      insert(:city, %{
        name: "Test City",
        parent_location_id: federal_state.id
      })

    school =
      insert(:school, %{
        name: "Test School",
        parent_location_id: city.id
      })

    {:ok,
     %{conn: conn, country: country, federal_state: federal_state, city: city, school: school}}
  end

  describe "index" do
    test "lists all locations as JSON", %{
      conn: conn,
      country: country,
      federal_state: federal_state,
      city: city,
      school: school
    } do
      conn = get(conn, ~p"/api/v2.0/locations")
      response = json_response(conn, 200)

      assert %{"data" => locations} = response
      assert is_list(locations)
      assert length(locations) >= 4

      # Find our test locations in the response
      country_data = Enum.find(locations, &(&1["id"] == country.id))
      state_data = Enum.find(locations, &(&1["id"] == federal_state.id))
      city_data = Enum.find(locations, &(&1["id"] == city.id))
      school_data = Enum.find(locations, &(&1["id"] == school.id))

      # Verify country data
      assert country_data["name"] == "Test Country"
      assert country_data["code"] == "TC"
      assert country_data["is_country"] == true
      assert country_data["is_federal_state"] == false
      assert country_data["parent_location_id"] == nil

      # Verify federal state data
      assert state_data["name"] == "Test State"
      assert state_data["code"] == "TS"
      assert state_data["is_federal_state"] == true
      assert state_data["is_country"] == false
      assert state_data["parent_location_id"] == country.id

      # Verify city data
      assert city_data["name"] == "Test City"
      assert city_data["is_city"] == true
      assert city_data["is_school"] == false
      assert city_data["parent_location_id"] == federal_state.id

      # Verify school data
      assert school_data["name"] == "Test School"
      assert school_data["is_school"] == true
      assert school_data["is_city"] == false
      assert school_data["parent_location_id"] == city.id
    end

    test "returns valid JSON structure", %{conn: conn} do
      conn = get(conn, ~p"/api/v2.0/locations")
      response = json_response(conn, 200)

      assert Map.has_key?(response, "data")
      assert is_list(response["data"])

      # Check that each location has the expected fields
      if length(response["data"]) > 0 do
        location = hd(response["data"])

        assert Map.has_key?(location, "id")
        assert Map.has_key?(location, "name")
        assert Map.has_key?(location, "code")
        assert Map.has_key?(location, "is_country")
        assert Map.has_key?(location, "is_federal_state")
        assert Map.has_key?(location, "is_county")
        assert Map.has_key?(location, "is_city")
        assert Map.has_key?(location, "is_school")
        assert Map.has_key?(location, "parent_location_id")
        assert Map.has_key?(location, "updated_at")
      end
    end
  end

  describe "show" do
    test "returns a single location as JSON", %{conn: conn, federal_state: federal_state} do
      conn = get(conn, ~p"/api/v2.0/locations/#{federal_state.id}")
      response = json_response(conn, 200)

      assert %{"data" => location_data} = response
      assert location_data["id"] == federal_state.id
      assert location_data["name"] == "Test State"
      assert location_data["code"] == "TS"
      assert location_data["is_federal_state"] == true
    end

    test "returns 404 for non-existent location", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(conn, ~p"/api/v2.0/locations/999999")
      end
    end
  end
end
