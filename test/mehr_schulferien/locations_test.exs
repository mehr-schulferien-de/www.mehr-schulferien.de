defmodule MehrSchulferien.LocationsTest do
  use MehrSchulferien.DataCase

  alias MehrSchulferien.Locations

  describe "countries" do
    alias MehrSchulferien.Locations.Country

    @valid_attrs %{name: "some name", slug: "some slug"}
    @update_attrs %{name: "some updated name", slug: "some updated slug"}
    @invalid_attrs %{name: nil, slug: nil}

    def country_fixture(attrs \\ %{}) do
      {:ok, country} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Locations.create_country()

      country
    end

    test "list_countries/0 returns all countries" do
      country = country_fixture()
      assert Locations.list_countries() == [country]
    end

    test "get_country!/1 returns the country with given id" do
      country = country_fixture()
      assert Locations.get_country!(country.id) == country
    end

    test "create_country/1 with valid data creates a country" do
      assert {:ok, %Country{} = country} = Locations.create_country(@valid_attrs)
      assert country.name == "some name"
      assert country.slug == "some slug"
    end

    test "create_country/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Locations.create_country(@invalid_attrs)
    end

    test "update_country/2 with valid data updates the country" do
      country = country_fixture()
      assert {:ok, %Country{} = country} = Locations.update_country(country, @update_attrs)
      assert country.name == "some updated name"
      assert country.slug == "some updated slug"
    end

    test "update_country/2 with invalid data returns error changeset" do
      country = country_fixture()
      assert {:error, %Ecto.Changeset{}} = Locations.update_country(country, @invalid_attrs)
      assert country == Locations.get_country!(country.id)
    end

    test "delete_country/1 deletes the country" do
      country = country_fixture()
      assert {:ok, %Country{}} = Locations.delete_country(country)
      assert_raise Ecto.NoResultsError, fn -> Locations.get_country!(country.id) end
    end

    test "change_country/1 returns a country changeset" do
      country = country_fixture()
      assert %Ecto.Changeset{} = Locations.change_country(country)
    end
  end
end
