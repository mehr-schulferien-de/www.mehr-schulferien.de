defmodule MehrSchulferien.LocationsTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory

  alias MehrSchulferien.{Locations, Locations.Flag, Locations.Location}

  describe "locations" do
    @valid_attrs %{
      is_country: true,
      name: "Deutschland",
      code: "D"
    }
    @update_attrs %{code: "DE"}
    @invalid_attrs %{name: nil}

    test "list_locations/0 returns all locations" do
      location = insert(:federal_state)
      assert locations = Locations.list_locations()
      assert location_1 = Enum.find(locations, &(&1.id == location.id))
      assert location.name == location_1.name
    end

    test "get_location!/1 returns the location with given id" do
      location = insert(:federal_state)
      assert Locations.get_location!(location.id) == location
    end

    test "recursive_location_ids/1 returns location's id and ancestor ids" do
      other_location = insert(:federal_state)
      location = insert(:federal_state)
      country = Locations.get_location!(location.parent_location_id)
      county = insert(:county, %{parent_location_id: location.id})
      location_ids = Locations.recursive_location_ids(country)
      assert location_ids == [country.id]
      location_ids = Locations.recursive_location_ids(location)
      assert location_ids == [country.id, location.id]
      location_ids = Locations.recursive_location_ids(county)
      assert location_ids == [country.id, location.id, county.id]
      assert other_location.id not in location_ids
    end

    test "create_location/1 with valid data creates a location" do
      assert {:ok, %Location{} = location} = Locations.create_location(@valid_attrs)
      assert location.is_country == true
      assert location.name == "Deutschland"
      assert location.slug == "deutschland"
    end

    test "create_location/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Locations.create_location(@invalid_attrs)
    end

    test "update_location/2 with valid data updates the location" do
      location = insert(:federal_state)
      assert {:ok, %Location{} = location} = Locations.update_location(location, @update_attrs)
      assert location.code == "DE"
    end

    test "update_location/2 with invalid data returns error changeset" do
      location = insert(:federal_state)
      assert {:error, %Ecto.Changeset{}} = Locations.update_location(location, @invalid_attrs)
      assert location == Locations.get_location!(location.id)
    end

    test "delete_location/1 deletes the location" do
      location = insert(:federal_state)
      assert {:ok, %Location{}} = Locations.delete_location(location)
      assert_raise Ecto.NoResultsError, fn -> Locations.get_location!(location.id) end
    end

    test "change_location/1 returns a location changeset" do
      location = insert(:federal_state)
      assert %Ecto.Changeset{} = Locations.change_location(location)
    end
  end

  describe "federal state data" do
    test "list_federal_states/1 returns a certain country's federal states" do
      country = insert(:country)
      federal_states = insert_list(3, :federal_state, %{parent_location_id: country.id})
      locations = Locations.list_federal_states(country)
      assert Enum.map(federal_states, & &1.id) == locations |> Enum.map(& &1.id) |> Enum.sort()
      assert Enum.filter(locations, &(&1.parent_location_id == country.id))
    end
  end

  describe "city data" do
    test "list_cities/1 returns a certain county's cities" do
      county = insert(:county)
      cities = insert_list(3, :city, %{parent_location_id: county.id})
      cities_ids = cities |> Enum.sort(&(&1.name >= &2.name)) |> Enum.map(& &1.id)
      _other_city = insert(:city)
      cities_1 = Locations.list_cities(county)
      cities_1_ids = Enum.map(cities_1, & &1.id)
      assert cities_1_ids == cities_ids
    end

    test "list_cities_of_country/1 returns a country's cities" do
      german_cities = add_country_cities("d")
      german_city_ids = Enum.map(german_cities, & &1.id)
      country = Locations.get_country_by_slug!("d")
      assert cities = Locations.list_cities_of_country(country)
      assert Enum.all?(cities, &(&1.id in german_city_ids))
      swiss_cities = add_country_cities("ch")
      swiss_city_ids = Enum.map(swiss_cities, & &1.id)
      country = Locations.get_country_by_slug!("ch")
      assert cities = Locations.list_cities_of_country(country)
      assert Enum.all?(cities, &(&1.id in swiss_city_ids))
      refute Enum.any?(cities, &(&1.id in german_city_ids))
    end
  end

  describe "school data" do
    test "list_schools_of_country/1 returns a country's schools" do
      german_cities = add_country_cities("d")
      german_schools = Enum.map(german_cities, &insert(:school, %{parent_location_id: &1.id}))
      german_school_ids = Enum.map(german_schools, & &1.id)
      country = Locations.get_country_by_slug!("d")
      assert schools = Locations.list_schools_of_country(country)
      assert Enum.all?(schools, &(&1.id in german_school_ids))
      swiss_cities = add_country_cities("ch")
      swiss_schools = Enum.map(swiss_cities, &insert(:school, %{parent_location_id: &1.id}))
      swiss_school_ids = Enum.map(swiss_schools, & &1.id)
      country = Locations.get_country_by_slug!("ch")
      assert schools = Locations.list_schools_of_country(country)
      assert Enum.all?(schools, &(&1.id in swiss_school_ids))
      refute Enum.any?(schools, &(&1.id in german_school_ids))
    end
  end

  describe "federal_state flags" do
    test "get_flag/1 show federal_state's flag" do
      assert flag = Flag.get_flag("BE")

      assert String.starts_with?(
               flag,
               "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAAAmBAMAAACG6oC"
             )

      assert String.ends_with?(flag, "Vybpdjzx/tp/2N/eAAB/V7H6iAYrgAAAABJRU5ErkJggg==")
    end

    test "get_flag/1 returns nil if flag cannot be found" do
      refute Flag.get_flag("CC")
    end
  end

  defp add_country_cities(slug) do
    country = insert(:country, slug: slug)
    federal_states = insert_list(3, :federal_state, %{parent_location_id: country.id})
    counties = Enum.map(federal_states, &insert(:county, %{parent_location_id: &1.id}))
    Enum.map(counties, &insert(:city, %{parent_location_id: &1.id}))
  end

  describe "list_counties_with_cities_having_schools/1" do
    setup do
      country = insert(:country, name: "Testland", slug: "testland")
      federal_state = insert(:federal_state, name: "Test State", slug: "test-state", parent_location_id: country.id)

      county1 = insert(:county, name: "County One", parent_location_id: federal_state.id)
      county2 = insert(:county, name: "County Two", parent_location_id: federal_state.id)
      county3 = insert(:county, name: "County Three (No Cities with Schools)", parent_location_id: federal_state.id)
      county4 = insert(:county, name: "County Four (No Cities)", parent_location_id: federal_state.id)


      city1_c1 = insert(:city, name: "City A (County One)", parent_location_id: county1.id)
      insert(:zip_code, value: "12345", city_id: city1_c1.id)
      insert_list(2, :school, parent_location_id: city1_c1.id) # 2 schools

      city2_c1 = insert(:city, name: "City B (County One, No Schools)", parent_location_id: county1.id)
      insert(:zip_code, value: "54321", city_id: city2_c1.id)
      # No schools in City B

      city1_c2 = insert(:city, name: "City C (County Two)", parent_location_id: county2.id)
      insert_list(1, :school, parent_location_id: city1_c2.id) # 1 school

      # County Three has a city, but that city has no schools
      city1_c3 = insert(:city, name: "City D (County Three, No Schools)", parent_location_id: county3.id)

      %{
        federal_state: federal_state,
        county1: county1,
        county2: county2,
        county3: county3,
        county4: county4,
        city1_c1: city1_c1,
        city2_c1: city2_c1,
        city1_c2: city1_c2,
        city1_c3: city1_c3
      }
    end

    test "returns counties with cities that have schools, including school count and zip codes", %{
      federal_state: federal_state,
      county1: county1,
      county2: county2,
      city1_c1: city1_c1,
      city1_c2: city1_c2
    } do
      result = Locations.list_counties_with_cities_having_schools(federal_state)

      # Expected: County One with City A (2 schools)
      #           County Two with City C (1 school)
      # County Three and Four should be filtered out.
      # City B (County One) should not be listed as it has no schools.

      assert length(result) == 2 # County One and County Two

      # Check County One
      {res_county1, cities_c1} = Enum.find(result, fn {c, _cs} -> c.id == county1.id end)
      assert res_county1.name == "County One"
      assert length(cities_c1) == 1 # Only City A

      city_a_data = Enum.find(cities_c1, fn c_data -> c_data.city_data.id == city1_c1.id end)
      assert city_a_data.city_data.name == "City A (County One)"
      assert city_a_data.school_count == 2
      assert city_a_data.city_data.zip_codes != [] # Check zip_codes are preloaded
      assert Enum.any?(city_a_data.city_data.zip_codes, &(&1.value == "12345"))

      # Check County Two
      {res_county2, cities_c2} = Enum.find(result, fn {c, _cs} -> c.id == county2.id end)
      assert res_county2.name == "County Two"
      assert length(cities_c2) == 1 # Only City C

      city_c_data = Enum.find(cities_c2, fn c_data -> c_data.city_data.id == city1_c2.id end)
      assert city_c_data.city_data.name == "City C (County Two)"
      assert city_c_data.school_count == 1
      assert city_c_data.city_data.zip_codes != nil # Can be empty list if no zips, but preloaded
    end

    test "returns empty list if federal state has no counties", %{} do
      country = insert(:country)
      federal_state_no_counties = insert(:federal_state, parent_location_id: country.id)
      result = Locations.list_counties_with_cities_having_schools(federal_state_no_counties)
      assert result == []
    end

    test "returns empty list if counties have no cities with schools", %{county4: county4, federal_state: federal_state} do
      # County4 has no cities at all.
      # County3 has a city, but that city has no schools.
      # We need to ensure that list_counties_with_cities_having_schools correctly filters these.
      # To isolate this test, let's imagine a federal state with only such counties.
      temp_country = insert(:country, name: "Temp Country")
      temp_fs = insert(:federal_state, name: "Temp FS", parent_location_id: temp_country.id)
      c_no_cities = insert(:county, name: "No Cities County", parent_location_id: temp_fs.id)
      c_city_no_schools = insert(:county, name: "City No Schools County", parent_location_id: temp_fs.id)
      insert(:city, name: "City With No Schools", parent_location_id: c_city_no_schools.id) # No schools here

      result = Locations.list_counties_with_cities_having_schools(temp_fs)
      assert result == []
    end
  end
end
