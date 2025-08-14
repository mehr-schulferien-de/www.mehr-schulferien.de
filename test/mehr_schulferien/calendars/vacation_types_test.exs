defmodule MehrSchulferien.Calendars.VacationTypesTest do
  use MehrSchulferien.DataCase, async: true

  alias MehrSchulferien.Calendars.VacationTypes
  alias MehrSchulferien.Calendars.HolidayOrVacationType
  alias MehrSchulferien.{Locations, Calendars, Periods}

  setup do
    # Create test data
    {:ok, country} =
      Locations.create_location(%{
        name: "Deutschland",
        slug: "deutschland",
        is_country: true
      })

    {:ok, federal_state} =
      Locations.create_location(%{
        name: "Bayern",
        slug: "bayern",
        is_federal_state: true,
        parent_location_id: country.id
      })

    {:ok, summer_vacation} =
      Calendars.create_holiday_or_vacation_type(%{
        name: "Sommerferien",
        slug: "sommerferien",
        colloquial: "Sommer",
        country_location_id: country.id,
        default_display_priority: 1,
        default_html_class: "primary",
        default_is_listed_below_month: true,
        default_is_school_vacation: true,
        default_is_public_holiday: false,
        default_is_valid_for_students: true,
        default_is_valid_for_everybody: false
      })

    {:ok, winter_vacation} =
      Calendars.create_holiday_or_vacation_type(%{
        name: "Winterferien",
        slug: "winterferien",
        colloquial: "Winter",
        country_location_id: country.id,
        default_display_priority: 2,
        default_html_class: "primary",
        default_is_listed_below_month: true,
        default_is_school_vacation: true,
        default_is_public_holiday: false,
        default_is_valid_for_students: true,
        default_is_valid_for_everybody: false
      })

    {:ok, public_holiday} =
      Calendars.create_holiday_or_vacation_type(%{
        name: "Tag der Arbeit",
        slug: "tag-der-arbeit",
        colloquial: "Tag der Arbeit",
        country_location_id: country.id,
        default_display_priority: 3,
        default_html_class: "danger",
        default_is_listed_below_month: true,
        # Not a school vacation
        default_is_school_vacation: false,
        default_is_public_holiday: true,
        default_is_valid_for_students: true,
        default_is_valid_for_everybody: true
      })

    %{
      country: country,
      federal_state: federal_state,
      summer_vacation: summer_vacation,
      winter_vacation: winter_vacation,
      public_holiday: public_holiday
    }
  end

  describe "list_for_federal_state/2" do
    test "returns vacation types used in the date range", %{
      federal_state: federal_state,
      summer_vacation: summer_vacation,
      winter_vacation: winter_vacation
    } do
      today = Date.utc_today()

      # Create a summer vacation period (10 days, within range)
      {:ok, _summer_period} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: summer_vacation.id,
          starts_on: Date.add(today, 30),
          ends_on: Date.add(today, 40),
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      # Create a winter vacation period (5 days, within range)
      {:ok, _winter_period} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: winter_vacation.id,
          starts_on: Date.add(today, -50),
          ends_on: Date.add(today, -45),
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      result = VacationTypes.list_for_federal_state(federal_state, today)

      assert length(result) == 2
      slugs = Enum.map(result, & &1.slug)
      assert "sommerferien" in slugs
      assert "winterferien" in slugs
    end

    test "excludes periods shorter than 3 days", %{
      federal_state: federal_state,
      summer_vacation: summer_vacation
    } do
      today = Date.utc_today()

      # Create a short period (2 days, should be excluded)
      {:ok, _short_period} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: summer_vacation.id,
          starts_on: Date.add(today, 10),
          # Only 2 days
          ends_on: Date.add(today, 11),
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      result = VacationTypes.list_for_federal_state(federal_state, today)

      assert length(result) == 0
    end

    test "excludes periods outside the date range", %{
      federal_state: federal_state,
      summer_vacation: summer_vacation
    } do
      today = Date.utc_today()

      # Create a period far in the past (outside 12-month range)
      {:ok, _old_period} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: summer_vacation.id,
          starts_on: Date.add(today, -400),
          ends_on: Date.add(today, -390),
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      result = VacationTypes.list_for_federal_state(federal_state, today)

      assert length(result) == 0
    end

    test "excludes non-school vacation types", %{
      federal_state: federal_state,
      public_holiday: public_holiday
    } do
      today = Date.utc_today()

      # Create a public holiday period (not a school vacation)
      {:ok, _holiday_period} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: public_holiday.id,
          starts_on: Date.add(today, 10),
          # Single day
          ends_on: Date.add(today, 10),
          is_school_vacation: false,
          is_public_holiday: true,
          is_valid_for_students: true,
          is_valid_for_everybody: true,
          created_by_email_address: "test@example.com"
        })

      result = VacationTypes.list_for_federal_state(federal_state, today)

      assert length(result) == 0
    end

    test "orders by display priority", %{
      federal_state: federal_state,
      summer_vacation: summer_vacation,
      winter_vacation: winter_vacation
    } do
      today = Date.utc_today()

      # Create periods for both vacation types
      {:ok, _summer_period} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: summer_vacation.id,
          starts_on: Date.add(today, 30),
          ends_on: Date.add(today, 40),
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      {:ok, _winter_period} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: winter_vacation.id,
          starts_on: Date.add(today, -50),
          ends_on: Date.add(today, -45),
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      result = VacationTypes.list_for_federal_state(federal_state, today)

      # Summer has priority 1, Winter has priority 2
      assert List.first(result).slug == "sommerferien"
      assert List.last(result).slug == "winterferien"
    end

    test "returns unique vacation types even with multiple periods", %{
      federal_state: federal_state,
      summer_vacation: summer_vacation
    } do
      today = Date.utc_today()

      # Create multiple summer vacation periods
      {:ok, _period1} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: summer_vacation.id,
          starts_on: Date.add(today, 30),
          ends_on: Date.add(today, 40),
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      {:ok, _period2} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: summer_vacation.id,
          starts_on: Date.add(today, 60),
          ends_on: Date.add(today, 70),
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      result = VacationTypes.list_for_federal_state(federal_state, today)

      # Should only return one summer vacation type
      assert length(result) == 1
      assert List.first(result).slug == "sommerferien"
    end
  end

  describe "exists_for_state?/2" do
    test "returns true when vacation type exists for state", %{
      federal_state: federal_state,
      summer_vacation: summer_vacation
    } do
      # Create a summer vacation period
      {:ok, _period} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: summer_vacation.id,
          starts_on: ~D[2024-07-01],
          ends_on: ~D[2024-08-15],
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      assert VacationTypes.exists_for_state?(federal_state, "sommerferien") == true
    end

    test "returns false when vacation type doesn't exist for state", %{
      federal_state: federal_state
    } do
      assert VacationTypes.exists_for_state?(federal_state, "nonexistent") == false
    end

    test "returns false when period is not a school vacation", %{
      federal_state: federal_state,
      public_holiday: public_holiday
    } do
      # Create a public holiday period
      {:ok, _period} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: public_holiday.id,
          starts_on: ~D[2024-05-01],
          ends_on: ~D[2024-05-01],
          is_school_vacation: false,
          is_public_holiday: true,
          is_valid_for_students: true,
          is_valid_for_everybody: true,
          created_by_email_address: "test@example.com"
        })

      assert VacationTypes.exists_for_state?(federal_state, "tag-der-arbeit") == false
    end

    test "returns false for different state", %{
      country: country,
      summer_vacation: summer_vacation
    } do
      # Create another federal state
      {:ok, other_state} =
        Locations.create_location(%{
          name: "Berlin",
          slug: "berlin",
          is_federal_state: true,
          parent_location_id: country.id
        })

      # Create period for the first state
      {:ok, first_state} =
        Locations.create_location(%{
          name: "Hamburg",
          slug: "hamburg",
          is_federal_state: true,
          parent_location_id: country.id
        })

      {:ok, _period} =
        Periods.create_period(%{
          location_id: first_state.id,
          holiday_or_vacation_type_id: summer_vacation.id,
          starts_on: ~D[2024-07-01],
          ends_on: ~D[2024-08-15],
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      # Check for the other state
      assert VacationTypes.exists_for_state?(other_state, "sommerferien") == false
    end
  end

  describe "exists_for_year?/3" do
    setup do
      # Create test country
      {:ok, country} =
        Locations.create_location(%{
          name: "Deutschland",
          slug: "d",
          is_country: true
        })

      # Create test federal state
      {:ok, federal_state} =
        Locations.create_location(%{
          name: "Niedersachsen",
          slug: "niedersachsen",
          is_federal_state: true,
          parent_location_id: country.id
        })

      easter_vacation =
        Repo.insert!(%HolidayOrVacationType{
          name: "Osterferien",
          colloquial: "Osterferien",
          slug: "oster",
          default_is_school_vacation: true,
          default_is_public_holiday: false,
          default_is_valid_for_students: true,
          default_is_valid_for_everybody: false,
          default_display_priority: 2,
          wikipedia_url: nil,
          country_location_id: country.id
        })

      {:ok, federal_state: federal_state, easter_vacation: easter_vacation}
    end

    test "returns true when vacation exists in the specified year", %{
      federal_state: federal_state,
      easter_vacation: easter_vacation
    } do
      {:ok, _period} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: easter_vacation.id,
          starts_on: ~D[2024-03-25],
          ends_on: ~D[2024-04-05],
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      assert VacationTypes.exists_for_year?(federal_state, "oster", 2024) == true
    end

    test "returns false when vacation doesn't exist in the specified year", %{
      federal_state: federal_state,
      easter_vacation: easter_vacation
    } do
      {:ok, _period} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: easter_vacation.id,
          starts_on: ~D[2024-03-25],
          ends_on: ~D[2024-04-05],
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      # Check for a different year
      assert VacationTypes.exists_for_year?(federal_state, "oster", 2016) == false
    end

    test "handles string year parameter", %{
      federal_state: federal_state,
      easter_vacation: easter_vacation
    } do
      {:ok, _period} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: easter_vacation.id,
          starts_on: ~D[2024-03-25],
          ends_on: ~D[2024-04-05],
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      assert VacationTypes.exists_for_year?(federal_state, "oster", "2024") == true
      assert VacationTypes.exists_for_year?(federal_state, "oster", "2016") == false
    end
  end

  describe "list_for_year/2" do
    setup do
      # Create test country
      {:ok, country} =
        Locations.create_location(%{
          name: "Deutschland",
          slug: "d",
          is_country: true
        })

      # Create test federal state
      {:ok, federal_state} =
        Locations.create_location(%{
          name: "Niedersachsen",
          slug: "niedersachsen",
          is_federal_state: true,
          parent_location_id: country.id
        })

      easter_vacation =
        Repo.insert!(%HolidayOrVacationType{
          name: "Osterferien",
          colloquial: "Osterferien",
          slug: "oster",
          default_is_school_vacation: true,
          default_is_public_holiday: false,
          default_is_valid_for_students: true,
          default_is_valid_for_everybody: false,
          default_display_priority: 2,
          wikipedia_url: nil,
          country_location_id: country.id
        })

      summer_vacation =
        Repo.insert!(%HolidayOrVacationType{
          name: "Sommerferien",
          colloquial: "Sommerferien",
          slug: "sommer",
          default_is_school_vacation: true,
          default_is_public_holiday: false,
          default_is_valid_for_students: true,
          default_is_valid_for_everybody: false,
          default_display_priority: 3,
          wikipedia_url: nil,
          country_location_id: country.id
        })

      {:ok,
       federal_state: federal_state,
       easter_vacation: easter_vacation,
       summer_vacation: summer_vacation}
    end

    test "returns vacation types that exist in the specified year", %{
      federal_state: federal_state,
      easter_vacation: easter_vacation,
      summer_vacation: summer_vacation
    } do
      # Create periods for 2024
      {:ok, _} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: easter_vacation.id,
          starts_on: ~D[2024-03-25],
          ends_on: ~D[2024-04-05],
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      {:ok, _} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: summer_vacation.id,
          starts_on: ~D[2024-07-01],
          ends_on: ~D[2024-08-15],
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      # Create a period for 2025 (should not be included when querying 2024)
      {:ok, _} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: easter_vacation.id,
          starts_on: ~D[2025-04-14],
          ends_on: ~D[2025-04-25],
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      result = VacationTypes.list_for_year(federal_state, 2024)
      slugs = Enum.map(result, & &1.slug)

      assert "oster" in slugs
      assert "sommer" in slugs
      assert length(result) == 2
    end

    test "returns empty list when no vacations exist for the year", %{
      federal_state: federal_state,
      easter_vacation: easter_vacation
    } do
      # Create a period for 2024
      {:ok, _} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: easter_vacation.id,
          starts_on: ~D[2024-03-25],
          ends_on: ~D[2024-04-05],
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      # Query for 2016 where no periods exist
      result = VacationTypes.list_for_year(federal_state, 2016)

      assert result == []
    end

    test "handles string year parameter", %{
      federal_state: federal_state,
      easter_vacation: easter_vacation
    } do
      {:ok, _} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: easter_vacation.id,
          starts_on: ~D[2024-03-25],
          ends_on: ~D[2024-04-05],
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          created_by_email_address: "test@example.com"
        })

      result = VacationTypes.list_for_year(federal_state, "2024")
      assert length(result) == 1
      assert List.first(result).slug == "oster"
    end
  end
end
