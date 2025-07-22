defmodule MehrSchulferien.LocationsGeographicTest do
  use MehrSchulferien.DataCase
  import MehrSchulferien.Factory

  alias MehrSchulferien.Locations

  describe "geographic distance calculations" do
    test "calculate_distance/4 correctly calculates distance between coordinates" do
      # Berlin to Munich (approximately 500km)
      distance = Locations.calculate_distance(52.5200, 13.4050, 48.1351, 11.5820)

      assert distance > 500
      assert distance < 510

      # Very close points (should be near 0)
      close_distance = Locations.calculate_distance(52.5200, 13.4050, 52.5201, 13.4051)
      assert close_distance < 0.1
    end
  end

  describe "geographic search functions with real data" do
    setup do
      # Create test location hierarchy
      country = insert(:country, name: "Deutschland")
      federal_state = insert(:federal_state, name: "Berlin", parent_location_id: country.id)
      county = insert(:county, name: "Berlin", parent_location_id: federal_state.id)
      city = insert(:city, name: "Berlin", parent_location_id: county.id)

      # Create schools with addresses
      school1 = insert(:school, name: "Test Grundschule", parent_location_id: city.id)

      _address1 =
        insert(:address,
          school_location_id: school1.id,
          zip_code: "10115",
          city: "Berlin",
          lat: 52.5200,
          lon: 13.4050
        )

      school2 = insert(:school, name: "Test Gymnasium", parent_location_id: city.id)

      _address2 =
        insert(:address,
          school_location_id: school2.id,
          zip_code: "10115",
          city: "Berlin",
          lat: 52.5250,
          lon: 13.4100
        )

      school3 = insert(:school, name: "Andere Schule", parent_location_id: city.id)

      _address3 =
        insert(:address,
          school_location_id: school3.id,
          zip_code: "10117",
          city: "Berlin",
          lat: 52.5300,
          lon: 13.4200
        )

      # School far away
      school4 = insert(:school, name: "Weit Entfernte Schule", parent_location_id: city.id)

      _address4 =
        insert(:address,
          school_location_id: school4.id,
          zip_code: "14195",
          city: "Berlin",
          lat: 52.4500,
          lon: 13.2800
        )

      # School without coordinates
      school5 = insert(:school, name: "Schule ohne Koordinaten", parent_location_id: city.id)

      _address5 =
        insert(:address,
          school_location_id: school5.id,
          zip_code: "10999",
          city: "Berlin"
        )

      %{
        school1: school1,
        school2: school2,
        school3: school3,
        school4: school4,
        school5: school5,
        city: city
      }
    end

    test "find_schools_by_same_zip_code/1 returns schools with same zip code", %{
      school1: school1,
      school2: school2
    } do
      results = Locations.find_schools_by_same_zip_code(school1)

      assert length(results) == 1
      assert hd(results).id == school2.id
    end

    test "find_schools_by_same_zip_code/1 returns empty list if no school has address", %{
      city: city
    } do
      school_no_address = insert(:school, name: "No Address School", parent_location_id: city.id)

      results = Locations.find_schools_by_same_zip_code(school_no_address)
      assert results == []
    end

    test "find_schools_within_radius/2 returns schools within specified radius", %{
      school1: school1
    } do
      results = Locations.find_schools_within_radius(school1, 5)

      # Should find school2 and school3 but not school4
      assert length(results) == 2
      school_names = Enum.map(results, & &1.name)
      assert "Test Gymnasium" in school_names
      assert "Andere Schule" in school_names
      refute "Weit Entfernte Schule" in school_names
    end

    test "find_schools_within_radius/2 includes distance information", %{school1: school1} do
      results = Locations.find_schools_within_radius(school1, 10)

      # Check that distance_km is populated
      Enum.each(results, fn school ->
        assert Map.has_key?(school, :distance_km)
        assert is_float(school.distance_km)
        assert school.distance_km > 0
      end)
    end

    test "find_schools_within_radius/2 handles schools without coordinates", %{school5: school5} do
      results = Locations.find_schools_within_radius(school5, 10)
      assert results == []
    end

    test "search_schools_by_name_within_radius/3 filters by name and radius", %{school1: school1} do
      results = Locations.search_schools_by_name_within_radius(school1, "Gymnasium", 5)

      assert length(results) == 1
      assert hd(results).name == "Test Gymnasium"
    end

    test "find_schools_in_same_city/1 returns all schools in the same city", %{school1: school1} do
      results = Locations.find_schools_in_same_city(school1)

      # Should find all other schools in the same city (4 others)
      assert length(results) == 4
      school_names = Enum.map(results, & &1.name)
      assert "Test Gymnasium" in school_names
      assert "Andere Schule" in school_names
      assert "Weit Entfernte Schule" in school_names
      assert "Schule ohne Koordinaten" in school_names
    end
  end
end
