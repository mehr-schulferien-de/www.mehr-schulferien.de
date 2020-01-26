defmodule MehrSchulferien.MapsTest do
  use MehrSchulferien.DataCase

  alias MehrSchulferien.Maps

  describe "locations" do
    alias MehrSchulferien.Maps.Location

    @valid_attrs %{is_city: true, is_country: true, is_county: true, is_federal_state: true, is_school: true, name: "some name", slug: "some slug"}
    @update_attrs %{is_city: false, is_country: false, is_county: false, is_federal_state: false, is_school: false, name: "some updated name", slug: "some updated slug"}
    @invalid_attrs %{is_city: nil, is_country: nil, is_county: nil, is_federal_state: nil, is_school: nil, name: nil, slug: nil}

    def location_fixture(attrs \\ %{}) do
      {:ok, location} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Maps.create_location()

      location
    end

    test "list_locations/0 returns all locations" do
      location = location_fixture()
      assert Maps.list_locations() == [location]
    end

    test "get_location!/1 returns the location with given id" do
      location = location_fixture()
      assert Maps.get_location!(location.id) == location
    end

    test "create_location/1 with valid data creates a location" do
      assert {:ok, %Location{} = location} = Maps.create_location(@valid_attrs)
      assert location.is_city == true
      assert location.is_country == true
      assert location.is_county == true
      assert location.is_federal_state == true
      assert location.is_school == true
      assert location.name == "some name"
      assert location.slug == "some slug"
    end

    test "create_location/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Maps.create_location(@invalid_attrs)
    end

    test "update_location/2 with valid data updates the location" do
      location = location_fixture()
      assert {:ok, %Location{} = location} = Maps.update_location(location, @update_attrs)
      assert location.is_city == false
      assert location.is_country == false
      assert location.is_county == false
      assert location.is_federal_state == false
      assert location.is_school == false
      assert location.name == "some updated name"
      assert location.slug == "some updated slug"
    end

    test "update_location/2 with invalid data returns error changeset" do
      location = location_fixture()
      assert {:error, %Ecto.Changeset{}} = Maps.update_location(location, @invalid_attrs)
      assert location == Maps.get_location!(location.id)
    end

    test "delete_location/1 deletes the location" do
      location = location_fixture()
      assert {:ok, %Location{}} = Maps.delete_location(location)
      assert_raise Ecto.NoResultsError, fn -> Maps.get_location!(location.id) end
    end

    test "change_location/1 returns a location changeset" do
      location = location_fixture()
      assert %Ecto.Changeset{} = Maps.change_location(location)
    end
  end

  describe "zip_codes" do
    alias MehrSchulferien.Maps.ZipCode

    @valid_attrs %{slug: "some slug", value: "some value"}
    @update_attrs %{slug: "some updated slug", value: "some updated value"}
    @invalid_attrs %{slug: nil, value: nil}

    def zip_code_fixture(attrs \\ %{}) do
      {:ok, zip_code} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Maps.create_zip_code()

      zip_code
    end

    test "list_zip_codes/0 returns all zip_codes" do
      zip_code = zip_code_fixture()
      assert Maps.list_zip_codes() == [zip_code]
    end

    test "get_zip_code!/1 returns the zip_code with given id" do
      zip_code = zip_code_fixture()
      assert Maps.get_zip_code!(zip_code.id) == zip_code
    end

    test "create_zip_code/1 with valid data creates a zip_code" do
      assert {:ok, %ZipCode{} = zip_code} = Maps.create_zip_code(@valid_attrs)
      assert zip_code.slug == "some slug"
      assert zip_code.value == "some value"
    end

    test "create_zip_code/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Maps.create_zip_code(@invalid_attrs)
    end

    test "update_zip_code/2 with valid data updates the zip_code" do
      zip_code = zip_code_fixture()
      assert {:ok, %ZipCode{} = zip_code} = Maps.update_zip_code(zip_code, @update_attrs)
      assert zip_code.slug == "some updated slug"
      assert zip_code.value == "some updated value"
    end

    test "update_zip_code/2 with invalid data returns error changeset" do
      zip_code = zip_code_fixture()
      assert {:error, %Ecto.Changeset{}} = Maps.update_zip_code(zip_code, @invalid_attrs)
      assert zip_code == Maps.get_zip_code!(zip_code.id)
    end

    test "delete_zip_code/1 deletes the zip_code" do
      zip_code = zip_code_fixture()
      assert {:ok, %ZipCode{}} = Maps.delete_zip_code(zip_code)
      assert_raise Ecto.NoResultsError, fn -> Maps.get_zip_code!(zip_code.id) end
    end

    test "change_zip_code/1 returns a zip_code changeset" do
      zip_code = zip_code_fixture()
      assert %Ecto.Changeset{} = Maps.change_zip_code(zip_code)
    end
  end

  describe "zip_code_mappings" do
    alias MehrSchulferien.Maps.ZipCodeMapping

    @valid_attrs %{lat: "some lat", lon: "some lon"}
    @update_attrs %{lat: "some updated lat", lon: "some updated lon"}
    @invalid_attrs %{lat: nil, lon: nil}

    def zip_code_mapping_fixture(attrs \\ %{}) do
      {:ok, zip_code_mapping} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Maps.create_zip_code_mapping()

      zip_code_mapping
    end

    test "list_zip_code_mappings/0 returns all zip_code_mappings" do
      zip_code_mapping = zip_code_mapping_fixture()
      assert Maps.list_zip_code_mappings() == [zip_code_mapping]
    end

    test "get_zip_code_mapping!/1 returns the zip_code_mapping with given id" do
      zip_code_mapping = zip_code_mapping_fixture()
      assert Maps.get_zip_code_mapping!(zip_code_mapping.id) == zip_code_mapping
    end

    test "create_zip_code_mapping/1 with valid data creates a zip_code_mapping" do
      assert {:ok, %ZipCodeMapping{} = zip_code_mapping} = Maps.create_zip_code_mapping(@valid_attrs)
      assert zip_code_mapping.lat == "some lat"
      assert zip_code_mapping.lon == "some lon"
    end

    test "create_zip_code_mapping/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Maps.create_zip_code_mapping(@invalid_attrs)
    end

    test "update_zip_code_mapping/2 with valid data updates the zip_code_mapping" do
      zip_code_mapping = zip_code_mapping_fixture()
      assert {:ok, %ZipCodeMapping{} = zip_code_mapping} = Maps.update_zip_code_mapping(zip_code_mapping, @update_attrs)
      assert zip_code_mapping.lat == "some updated lat"
      assert zip_code_mapping.lon == "some updated lon"
    end

    test "update_zip_code_mapping/2 with invalid data returns error changeset" do
      zip_code_mapping = zip_code_mapping_fixture()
      assert {:error, %Ecto.Changeset{}} = Maps.update_zip_code_mapping(zip_code_mapping, @invalid_attrs)
      assert zip_code_mapping == Maps.get_zip_code_mapping!(zip_code_mapping.id)
    end

    test "delete_zip_code_mapping/1 deletes the zip_code_mapping" do
      zip_code_mapping = zip_code_mapping_fixture()
      assert {:ok, %ZipCodeMapping{}} = Maps.delete_zip_code_mapping(zip_code_mapping)
      assert_raise Ecto.NoResultsError, fn -> Maps.get_zip_code_mapping!(zip_code_mapping.id) end
    end

    test "change_zip_code_mapping/1 returns a zip_code_mapping changeset" do
      zip_code_mapping = zip_code_mapping_fixture()
      assert %Ecto.Changeset{} = Maps.change_zip_code_mapping(zip_code_mapping)
    end
  end
end
