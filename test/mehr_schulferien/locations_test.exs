defmodule MehrSchulferien.LocationsTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  alias MehrSchulferien.{Locations, Locations.Flag, Locations.Location}
  alias MehrSchulferien.Repo
  import Ecto.Query

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

  describe "delete_school/2" do
    test "deletes a school and backs up data to deleted tables" do
      # Create a school with address
      country = insert(:country)
      federal_state = insert(:federal_state, parent_location_id: country.id)
      county = insert(:county, parent_location_id: federal_state.id)
      city = insert(:city, parent_location_id: county.id)
      school = insert(:school, parent_location_id: city.id)

      # Create an address for the school
      address = insert(:address, school_location_id: school.id)

      # Create some periods for the school - use unique names to avoid conflicts
      {:ok, vacation_type} =
        Repo.insert(%MehrSchulferien.Calendars.HolidayOrVacationType{
          country_location_id: country.id,
          name: "Test Vacation #{System.unique_integer([:positive])}",
          slug: "test-vacation-#{System.unique_integer([:positive])}",
          colloquial: "Test Vacation",
          default_display_priority: 3,
          default_html_class: "green",
          default_is_listed_below_month: true,
          default_is_school_vacation: true,
          default_is_valid_for_students: true
        })

      {:ok, holiday_type} =
        Repo.insert(%MehrSchulferien.Calendars.HolidayOrVacationType{
          country_location_id: country.id,
          name: "Test Holiday #{System.unique_integer([:positive])}",
          slug: "test-holiday-#{System.unique_integer([:positive])}",
          colloquial: "Test Holiday",
          default_display_priority: 3,
          default_html_class: "green",
          default_is_public_holiday: true,
          default_is_valid_for_everybody: true
        })

      {:ok, period1} =
        Repo.insert(%MehrSchulferien.Periods.Period{
          location_id: school.id,
          holiday_or_vacation_type_id: vacation_type.id,
          starts_on: ~D[2024-07-01],
          ends_on: ~D[2024-08-31],
          is_school_vacation: true,
          is_valid_for_students: true,
          created_by_email_address: "test@example.com"
        })

      {:ok, period2} =
        Repo.insert(%MehrSchulferien.Periods.Period{
          location_id: school.id,
          holiday_or_vacation_type_id: holiday_type.id,
          starts_on: ~D[2024-12-25],
          ends_on: ~D[2024-12-25],
          is_public_holiday: true,
          is_valid_for_everybody: true,
          created_by_email_address: "test@example.com"
        })

      # Delete the school
      assert {:ok, %{school: deleted_school, periods: deleted_periods}} =
               Locations.delete_school(school,
                 deleted_by_user_id: 123,
                 deletion_reason: "Test deletion"
               )

      # Verify the school is deleted from the original table
      assert_raise Ecto.NoResultsError, fn ->
        Locations.get_location!(school.id)
      end

      # Verify the address is deleted
      assert is_nil(Repo.get(MehrSchulferien.Maps.Address, address.id))

      # Verify the periods are deleted from the original table
      assert [] =
               Repo.all(
                 from p in MehrSchulferien.Periods.Period, where: p.location_id == ^school.id
               )

      # Verify the school is in the deleted_schools table
      assert deleted_school.original_id == school.id
      assert deleted_school.name == school.name
      assert deleted_school.slug == school.slug
      assert deleted_school.parent_location_id == school.parent_location_id
      assert deleted_school.is_school == true
      assert deleted_school.deleted_by_user_id == 123
      assert deleted_school.deletion_reason == "Test deletion"
      assert deleted_school.deleted_at != nil

      # Verify address fields are backed up
      assert deleted_school.address_street == address.street
      assert deleted_school.address_zip_code == address.zip_code
      assert deleted_school.address_city == address.city
      assert deleted_school.address_email_address == address.email_address
      assert deleted_school.address_phone_number == address.phone_number

      # Verify the periods are in the deleted_periods table
      assert length(deleted_periods) == 2

      deleted_period1 = Enum.find(deleted_periods, &(&1.original_id == period1.id))
      assert deleted_period1.starts_on == period1.starts_on
      assert deleted_period1.ends_on == period1.ends_on
      assert deleted_period1.holiday_or_vacation_type_id == period1.holiday_or_vacation_type_id
      assert deleted_period1.is_school_vacation == true
      assert deleted_period1.deleted_school_original_id == school.id
      assert deleted_period1.deleted_by_user_id == 123
      assert deleted_period1.deleted_at != nil

      deleted_period2 = Enum.find(deleted_periods, &(&1.original_id == period2.id))
      assert deleted_period2.starts_on == period2.starts_on
      assert deleted_period2.ends_on == period2.ends_on
      assert deleted_period2.holiday_or_vacation_type_id == period2.holiday_or_vacation_type_id
      assert deleted_period2.is_public_holiday == true
      assert deleted_period2.deleted_school_original_id == school.id
    end

    test "deletes a school without address" do
      # Create a school without address
      country = insert(:country)
      federal_state = insert(:federal_state, parent_location_id: country.id)
      county = insert(:county, parent_location_id: federal_state.id)
      city = insert(:city, parent_location_id: county.id)
      school = insert(:school, parent_location_id: city.id)

      # Delete the school
      assert {:ok, %{school: deleted_school, periods: _}} =
               Locations.delete_school(school)

      # Verify the school is deleted
      assert_raise Ecto.NoResultsError, fn ->
        Locations.get_location!(school.id)
      end

      # Verify the school is backed up
      assert deleted_school.original_id == school.id
      assert deleted_school.name == school.name

      # Verify address fields are nil
      assert is_nil(deleted_school.address_street)
      assert is_nil(deleted_school.address_zip_code)
      assert is_nil(deleted_school.address_city)
    end

    test "returns error when trying to delete non-school location" do
      city = insert(:city)

      assert {:error, :not_a_school} = Locations.delete_school(city)

      # Verify the city still exists
      assert Locations.get_location!(city.id)
    end
  end

  # This helper is already using the factory pattern correctly
  defp add_country_cities(slug) do
    country = get_or_create_country(slug)
    federal_states = insert_list(3, :federal_state, %{parent_location_id: country.id})
    counties = Enum.map(federal_states, &insert(:county, %{parent_location_id: &1.id}))
    Enum.map(counties, &insert(:city, %{parent_location_id: &1.id}))
  end
end
