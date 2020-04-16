defmodule MehrSchulferien.LocationsTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory

  alias MehrSchulferien.{Locations, Locations.Location}

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
      assert Enum.map(federal_states, & &1.id) == Enum.map(locations, & &1.id)
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

  defp add_country_cities(slug) do
    country = insert(:country, slug: slug)
    federal_states = insert_list(3, :federal_state, %{parent_location_id: country.id})
    counties = Enum.map(federal_states, &insert(:county, %{parent_location_id: &1.id}))
    Enum.map(counties, &insert(:city, %{parent_location_id: &1.id}))
  end
end
