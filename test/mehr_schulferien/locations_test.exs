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
      assert {:ok, %FederalState{} = federal_state} = Locations.update_federal_state(federal_state, @update_attrs)
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
      assert {:ok, %City{} = city} = Locations.update_city(city, @update_attrs)
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

  describe "zip_codes" do
    alias MehrSchulferien.Locations.ZipCode

    @valid_attrs %{value: "some value"}
    @update_attrs %{value: "some updated value"}
    @invalid_attrs %{value: nil}

    def zip_code_fixture(attrs \\ %{}) do
      {:ok, zip_code} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Locations.create_zip_code()

      zip_code
    end

    test "list_zip_codes/0 returns all zip_codes" do
      zip_code = zip_code_fixture()
      assert Locations.list_zip_codes() == [zip_code]
    end

    test "get_zip_code!/1 returns the zip_code with given id" do
      zip_code = zip_code_fixture()
      assert Locations.get_zip_code!(zip_code.id) == zip_code
    end

    test "create_zip_code/1 with valid data creates a zip_code" do
      assert {:ok, %ZipCode{} = zip_code} = Locations.create_zip_code(@valid_attrs)
      assert zip_code.value == "some value"
    end

    test "create_zip_code/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Locations.create_zip_code(@invalid_attrs)
    end

    test "update_zip_code/2 with valid data updates the zip_code" do
      zip_code = zip_code_fixture()
      assert {:ok, %ZipCode{} = zip_code} = Locations.update_zip_code(zip_code, @update_attrs)
      assert zip_code.value == "some updated value"
    end

    test "update_zip_code/2 with invalid data returns error changeset" do
      zip_code = zip_code_fixture()
      assert {:error, %Ecto.Changeset{}} = Locations.update_zip_code(zip_code, @invalid_attrs)
      assert zip_code == Locations.get_zip_code!(zip_code.id)
    end

    test "delete_zip_code/1 deletes the zip_code" do
      zip_code = zip_code_fixture()
      assert {:ok, %ZipCode{}} = Locations.delete_zip_code(zip_code)
      assert_raise Ecto.NoResultsError, fn -> Locations.get_zip_code!(zip_code.id) end
    end

    test "change_zip_code/1 returns a zip_code changeset" do
      zip_code = zip_code_fixture()
      assert %Ecto.Changeset{} = Locations.change_zip_code(zip_code)
    end
  end
end
