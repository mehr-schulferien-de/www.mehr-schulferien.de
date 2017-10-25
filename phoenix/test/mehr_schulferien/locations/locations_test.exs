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
      assert {:ok, country} = Locations.update_country(country, @update_attrs)
      assert %Country{} = country
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

  describe "federal_states" do
    alias MehrSchulferien.Locations.FederalState

    @valid_attrs %{code: "some code", name: "some name", slug: "some slug"}
    @update_attrs %{code: "some updated code", name: "some updated name", slug: "some updated slug"}
    @invalid_attrs %{code: nil, name: nil, slug: nil}

    def federal_state_fixture(attrs \\ %{}) do
      {:ok, federal_state} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Locations.create_federal_state()

      federal_state
    end

    test "list_federal_states/0 returns all federal_states" do
      federal_state = federal_state_fixture()
      assert Locations.list_federal_states() == [federal_state]
    end

    test "get_federal_state!/1 returns the federal_state with given id" do
      federal_state = federal_state_fixture()
      assert Locations.get_federal_state!(federal_state.id) == federal_state
    end

    test "create_federal_state/1 with valid data creates a federal_state" do
      assert {:ok, %FederalState{} = federal_state} = Locations.create_federal_state(@valid_attrs)
      assert federal_state.code == "some code"
      assert federal_state.name == "some name"
      assert federal_state.slug == "some slug"
    end

    test "create_federal_state/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Locations.create_federal_state(@invalid_attrs)
    end

    test "update_federal_state/2 with valid data updates the federal_state" do
      federal_state = federal_state_fixture()
      assert {:ok, federal_state} = Locations.update_federal_state(federal_state, @update_attrs)
      assert %FederalState{} = federal_state
      assert federal_state.code == "some updated code"
      assert federal_state.name == "some updated name"
      assert federal_state.slug == "some updated slug"
    end

    test "update_federal_state/2 with invalid data returns error changeset" do
      federal_state = federal_state_fixture()
      assert {:error, %Ecto.Changeset{}} = Locations.update_federal_state(federal_state, @invalid_attrs)
      assert federal_state == Locations.get_federal_state!(federal_state.id)
    end

    test "delete_federal_state/1 deletes the federal_state" do
      federal_state = federal_state_fixture()
      assert {:ok, %FederalState{}} = Locations.delete_federal_state(federal_state)
      assert_raise Ecto.NoResultsError, fn -> Locations.get_federal_state!(federal_state.id) end
    end

    test "change_federal_state/1 returns a federal_state changeset" do
      federal_state = federal_state_fixture()
      assert %Ecto.Changeset{} = Locations.change_federal_state(federal_state)
    end
  end

  describe "cities" do
    alias MehrSchulferien.Locations.City

    @valid_attrs %{name: "some name", slug: "some slug", zip_code: "some zip_code"}
    @update_attrs %{name: "some updated name", slug: "some updated slug", zip_code: "some updated zip_code"}
    @invalid_attrs %{name: nil, slug: nil, zip_code: nil}

    def city_fixture(attrs \\ %{}) do
      {:ok, city} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Locations.create_city()

      city
    end

    test "list_cities/0 returns all cities" do
      city = city_fixture()
      assert Locations.list_cities() == [city]
    end

    test "get_city!/1 returns the city with given id" do
      city = city_fixture()
      assert Locations.get_city!(city.id) == city
    end

    test "create_city/1 with valid data creates a city" do
      assert {:ok, %City{} = city} = Locations.create_city(@valid_attrs)
      assert city.name == "some name"
      assert city.slug == "some slug"
      assert city.zip_code == "some zip_code"
    end

    test "create_city/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Locations.create_city(@invalid_attrs)
    end

    test "update_city/2 with valid data updates the city" do
      city = city_fixture()
      assert {:ok, city} = Locations.update_city(city, @update_attrs)
      assert %City{} = city
      assert city.name == "some updated name"
      assert city.slug == "some updated slug"
      assert city.zip_code == "some updated zip_code"
    end

    test "update_city/2 with invalid data returns error changeset" do
      city = city_fixture()
      assert {:error, %Ecto.Changeset{}} = Locations.update_city(city, @invalid_attrs)
      assert city == Locations.get_city!(city.id)
    end

    test "delete_city/1 deletes the city" do
      city = city_fixture()
      assert {:ok, %City{}} = Locations.delete_city(city)
      assert_raise Ecto.NoResultsError, fn -> Locations.get_city!(city.id) end
    end

    test "change_city/1 returns a city changeset" do
      city = city_fixture()
      assert %Ecto.Changeset{} = Locations.change_city(city)
    end
  end

  describe "schools" do
    alias MehrSchulferien.Locations.School

    @valid_attrs %{address_city: "some address_city", address_line1: "some address_line1", address_line2: "some address_line2", address_street: "some address_street", address_zip_code: "some address_zip_code", email_address: "some email_address", fax_number: "some fax_number", homepage_url: "some homepage_url", name: "some name", phone_number: "some phone_number", slug: "some slug"}
    @update_attrs %{address_city: "some updated address_city", address_line1: "some updated address_line1", address_line2: "some updated address_line2", address_street: "some updated address_street", address_zip_code: "some updated address_zip_code", email_address: "some updated email_address", fax_number: "some updated fax_number", homepage_url: "some updated homepage_url", name: "some updated name", phone_number: "some updated phone_number", slug: "some updated slug"}
    @invalid_attrs %{address_city: nil, address_line1: nil, address_line2: nil, address_street: nil, address_zip_code: nil, email_address: nil, fax_number: nil, homepage_url: nil, name: nil, phone_number: nil, slug: nil}

    def school_fixture(attrs \\ %{}) do
      {:ok, school} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Locations.create_school()

      school
    end

    test "list_schools/0 returns all schools" do
      school = school_fixture()
      assert Locations.list_schools() == [school]
    end

    test "get_school!/1 returns the school with given id" do
      school = school_fixture()
      assert Locations.get_school!(school.id) == school
    end

    test "create_school/1 with valid data creates a school" do
      assert {:ok, %School{} = school} = Locations.create_school(@valid_attrs)
      assert school.address_city == "some address_city"
      assert school.address_line1 == "some address_line1"
      assert school.address_line2 == "some address_line2"
      assert school.address_street == "some address_street"
      assert school.address_zip_code == "some address_zip_code"
      assert school.email_address == "some email_address"
      assert school.fax_number == "some fax_number"
      assert school.homepage_url == "some homepage_url"
      assert school.name == "some name"
      assert school.phone_number == "some phone_number"
      assert school.slug == "some slug"
    end

    test "create_school/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Locations.create_school(@invalid_attrs)
    end

    test "update_school/2 with valid data updates the school" do
      school = school_fixture()
      assert {:ok, school} = Locations.update_school(school, @update_attrs)
      assert %School{} = school
      assert school.address_city == "some updated address_city"
      assert school.address_line1 == "some updated address_line1"
      assert school.address_line2 == "some updated address_line2"
      assert school.address_street == "some updated address_street"
      assert school.address_zip_code == "some updated address_zip_code"
      assert school.email_address == "some updated email_address"
      assert school.fax_number == "some updated fax_number"
      assert school.homepage_url == "some updated homepage_url"
      assert school.name == "some updated name"
      assert school.phone_number == "some updated phone_number"
      assert school.slug == "some updated slug"
    end

    test "update_school/2 with invalid data returns error changeset" do
      school = school_fixture()
      assert {:error, %Ecto.Changeset{}} = Locations.update_school(school, @invalid_attrs)
      assert school == Locations.get_school!(school.id)
    end

    test "delete_school/1 deletes the school" do
      school = school_fixture()
      assert {:ok, %School{}} = Locations.delete_school(school)
      assert_raise Ecto.NoResultsError, fn -> Locations.get_school!(school.id) end
    end

    test "change_school/1 returns a school changeset" do
      school = school_fixture()
      assert %Ecto.Changeset{} = Locations.change_school(school)
    end
  end
end
