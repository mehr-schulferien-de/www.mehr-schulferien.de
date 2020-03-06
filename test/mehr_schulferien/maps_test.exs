defmodule MehrSchulferien.MapsTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory

  alias MehrSchulferien.Maps
  alias MehrSchulferien.Maps.{Location, ZipCode, ZipCodeMapping}

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
      assert locations = Maps.list_locations()
      assert location_1 = Enum.find(locations, &(&1.id == location.id))
      assert location.name == location_1.name
    end

    test "get_location!/1 returns the location with given id" do
      location = insert(:federal_state)
      assert Maps.get_location!(location.id) == location
    end

    test "recursive_location_ids/1 returns location's id and ancestor ids" do
      other_location = insert(:federal_state)
      location = insert(:federal_state)
      country = Maps.get_location!(location.parent_location_id)
      county = insert(:county, %{parent_location_id: location.id})
      location_ids = Maps.recursive_location_ids(country)
      assert location_ids == [country.id]
      location_ids = Maps.recursive_location_ids(location)
      assert location_ids == [country.id, location.id]
      location_ids = Maps.recursive_location_ids(county)
      assert location_ids == [country.id, location.id, county.id]
      assert other_location.id not in location_ids
    end

    test "create_location/1 with valid data creates a location" do
      assert {:ok, %Location{} = location} = Maps.create_location(@valid_attrs)
      assert location.is_country == true
      assert location.name == "Deutschland"
      assert location.slug == "deutschland"
    end

    test "create_location/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Maps.create_location(@invalid_attrs)
    end

    test "update_location/2 with valid data updates the location" do
      location = insert(:location)
      assert {:ok, %Location{} = location} = Maps.update_location(location, @update_attrs)
      assert location.code == "DE"
    end

    test "update_location/2 with invalid data returns error changeset" do
      location = insert(:location)
      assert {:error, %Ecto.Changeset{}} = Maps.update_location(location, @invalid_attrs)
      assert location == Maps.get_location!(location.id)
    end

    test "delete_location/1 deletes the location" do
      location = insert(:location)
      assert {:ok, %Location{}} = Maps.delete_location(location)
      assert_raise Ecto.NoResultsError, fn -> Maps.get_location!(location.id) end
    end

    test "change_location/1 returns a location changeset" do
      location = insert(:location)
      assert %Ecto.Changeset{} = Maps.change_location(location)
    end
  end

  describe "zip_codes" do
    @valid_attrs %{value: "17890"}
    @update_attrs %{value: "17891"}
    @invalid_attrs %{value: nil}

    test "list_zip_codes/0 returns all zip_codes" do
      zip_code = insert(:zip_code)
      assert Maps.list_zip_codes() == [zip_code]
    end

    test "get_zip_code!/1 returns the zip_code with given id" do
      zip_code = insert(:zip_code)
      assert Maps.get_zip_code!(zip_code.id) == zip_code
    end

    test "create_zip_code/1 with valid data creates a zip_code" do
      country = insert(:country)
      valid_attrs = Map.put(@valid_attrs, :country_location_id, country.id)
      assert {:ok, %ZipCode{} = zip_code} = Maps.create_zip_code(valid_attrs)
      assert zip_code.slug == "17890"
      assert zip_code.value == "17890"
    end

    test "create_zip_code/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Maps.create_zip_code(@invalid_attrs)
    end

    test "update_zip_code/2 with valid data updates the zip_code" do
      zip_code = insert(:zip_code)
      assert {:ok, %ZipCode{} = zip_code} = Maps.update_zip_code(zip_code, @update_attrs)
      assert zip_code.value == "17891"
    end

    test "update_zip_code/2 with invalid data returns error changeset" do
      zip_code = insert(:zip_code)
      assert {:error, %Ecto.Changeset{}} = Maps.update_zip_code(zip_code, @invalid_attrs)
      assert zip_code == Maps.get_zip_code!(zip_code.id)
    end

    test "delete_zip_code/1 deletes the zip_code" do
      zip_code = insert(:zip_code)
      assert {:ok, %ZipCode{}} = Maps.delete_zip_code(zip_code)
      assert_raise Ecto.NoResultsError, fn -> Maps.get_zip_code!(zip_code.id) end
    end

    test "change_zip_code/1 returns a zip_code changeset" do
      zip_code = insert(:zip_code)
      assert %Ecto.Changeset{} = Maps.change_zip_code(zip_code)
    end
  end

  describe "zip_code_mappings" do
    @valid_attrs %{lat: 5.2, lon: 10.5}
    @update_attrs %{lon: 10.4}
    @invalid_attrs %{location_id: nil}

    test "list_zip_code_mappings/0 returns all zip_code_mappings" do
      zip_code_mapping = insert(:zip_code_mapping)
      assert Maps.list_zip_code_mappings() == [zip_code_mapping]
    end

    test "get_zip_code_mapping!/1 returns the zip_code_mapping with given id" do
      zip_code_mapping = insert(:zip_code_mapping)
      assert Maps.get_zip_code_mapping!(zip_code_mapping.id) == zip_code_mapping
    end

    test "create_zip_code_mapping/1 with valid data creates a zip_code_mapping" do
      location = insert(:city)
      zip_code = insert(:zip_code)
      valid_attrs = Map.merge(@valid_attrs, %{location_id: location.id, zip_code_id: zip_code.id})

      assert {:ok, %ZipCodeMapping{} = zip_code_mapping} =
               Maps.create_zip_code_mapping(valid_attrs)

      assert zip_code_mapping.lat == 5.2
      assert zip_code_mapping.lon == 10.5
    end

    test "create_zip_code_mapping/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Maps.create_zip_code_mapping(@invalid_attrs)
    end

    test "update_zip_code_mapping/2 with valid data updates the zip_code_mapping" do
      zip_code_mapping = insert(:zip_code_mapping)

      assert {:ok, %ZipCodeMapping{} = zip_code_mapping} =
               Maps.update_zip_code_mapping(zip_code_mapping, @update_attrs)

      assert zip_code_mapping.lon == 10.4
    end

    test "delete_zip_code_mapping/1 deletes the zip_code_mapping" do
      zip_code_mapping = insert(:zip_code_mapping)
      assert {:ok, %ZipCodeMapping{}} = Maps.delete_zip_code_mapping(zip_code_mapping)
      assert_raise Ecto.NoResultsError, fn -> Maps.get_zip_code_mapping!(zip_code_mapping.id) end
    end

    test "change_zip_code_mapping/1 returns a zip_code_mapping changeset" do
      zip_code_mapping = insert(:zip_code_mapping)
      assert %Ecto.Changeset{} = Maps.change_zip_code_mapping(zip_code_mapping)
    end
  end
end
