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
end
