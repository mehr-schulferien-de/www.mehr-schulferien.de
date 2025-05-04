defmodule MehrSchulferien.BridgeDaysTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory

  alias MehrSchulferien.{BridgeDays, Periods}

  describe "next_bridge_day" do
    test "find_next_bridge_day/2 finds the next bridge day for a federal state" do
      # Create a test setup with a known federal state
      country = insert(:country, %{name: "Deutschland", code: "DE"})

      hamburg =
        insert(:federal_state, %{
          name: "Hamburg",
          code: "HH",
          parent_location_id: country.id
        })

      # Create holidays and weekends for the test
      create_test_periods(country.id, hamburg.id)

      # Test with a fixed date reference (April 4, 2025)
      current_date = ~D[2025-04-04]

      # Find the next bridge day
      result = BridgeDays.find_next_bridge_day(hamburg, current_date)

      # Verify the result - May 2 is a Friday between Labor Day (May 1) and the weekend (May 3-4)
      assert result.starts_on == ~D[2025-05-02]
      assert result.ends_on == ~D[2025-05-02]
      assert result.number_days == 1
    end

    test "find_next_bridge_day/3 respects the number of days parameter" do
      # Create a test setup with a known federal state
      country = insert(:country, %{name: "Deutschland", code: "DE"})

      hamburg =
        insert(:federal_state, %{
          name: "Hamburg",
          code: "HH",
          parent_location_id: country.id
        })

      # Create holidays and weekends for the test
      create_test_periods(country.id, hamburg.id)

      # Test with a fixed date reference (April 4, 2025)
      current_date = ~D[2025-04-04]

      # Looking for a bridge day with 1 day
      result_1_day = BridgeDays.find_next_bridge_day(hamburg, current_date, 1)
      assert result_1_day.starts_on == ~D[2025-05-02]
      assert result_1_day.ends_on == ~D[2025-05-02]
      assert result_1_day.number_days == 1

      # Looking for a "bridge day" with 2 days (which should return nil in this test case)
      result_2_days = BridgeDays.find_next_bridge_day(hamburg, current_date, 2)
      assert result_2_days == nil
    end

    test "find_next_bridge_day/2 correctly skips past bridge days" do
      # Create a test setup with a known federal state
      country = insert(:country, %{name: "Deutschland", code: "DE"})

      hamburg =
        insert(:federal_state, %{
          name: "Hamburg",
          code: "HH",
          parent_location_id: country.id
        })

      # Create holidays and weekends for the test
      create_test_periods(country.id, hamburg.id)

      # Test with a date AFTER the first bridge day (May 4, 2025)
      current_date = ~D[2025-05-04]

      # Find the next bridge day - should be May 30 not May 2 (which is in the past)
      result = BridgeDays.find_next_bridge_day(hamburg, current_date)

      # Verify the result - May 30 is a Friday between Ascension Day (May 29) and the weekend (May 31-June 1)
      assert result.starts_on == ~D[2025-05-30]
      assert result.ends_on == ~D[2025-05-30]
      assert result.number_days == 1
    end
  end

  # Helper function to create test period data
  defp create_test_periods(country_id, location_id) do
    # Create holiday types
    {:ok, holiday_type} =
      MehrSchulferien.Calendars.create_holiday_or_vacation_type(%{
        name: "Feiertag",
        colloquial: "Feiertag",
        default_display_priority: 3,
        default_html_class: "danger",
        default_is_listed_below_month: true,
        default_is_public_holiday: true,
        default_is_valid_for_everybody: true,
        slug: "feiertag",
        wikipedia_url: "https://de.wikipedia.org/wiki/Feiertag",
        country_location_id: country_id
      })

    {:ok, weekend_type} =
      MehrSchulferien.Calendars.create_holiday_or_vacation_type(%{
        name: "Wochenende",
        colloquial: "Wochenende",
        default_display_priority: 2,
        default_html_class: "info",
        default_is_listed_below_month: true,
        default_is_valid_for_everybody: true,
        slug: "wochenende",
        wikipedia_url: "https://de.wikipedia.org/wiki/Wochenende",
        country_location_id: country_id
      })

    # Public holidays for 2025
    # May 1, 2025 (Thursday) - Labor Day
    Periods.create_period(%{
      is_public_holiday: true,
      is_valid_for_everybody: true,
      location_id: location_id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: ~D[2025-05-01],
      ends_on: ~D[2025-05-01],
      created_by_email_address: "test@example.com",
      display_priority: 10
    })

    # May 29, 2025 (Thursday) - Ascension Day
    Periods.create_period(%{
      is_public_holiday: true,
      is_valid_for_everybody: true,
      location_id: location_id,
      holiday_or_vacation_type_id: holiday_type.id,
      starts_on: ~D[2025-05-29],
      ends_on: ~D[2025-05-29],
      created_by_email_address: "test@example.com",
      display_priority: 10
    })

    # Weekend days
    # May 3-4, 2025 (Saturday-Sunday)
    Periods.create_period(%{
      is_valid_for_everybody: true,
      location_id: location_id,
      holiday_or_vacation_type_id: weekend_type.id,
      starts_on: ~D[2025-05-03],
      ends_on: ~D[2025-05-04],
      created_by_email_address: "test@example.com",
      display_priority: 5
    })

    # May 10-11, 2025 (Saturday-Sunday)
    Periods.create_period(%{
      is_valid_for_everybody: true,
      location_id: location_id,
      holiday_or_vacation_type_id: weekend_type.id,
      starts_on: ~D[2025-05-10],
      ends_on: ~D[2025-05-11],
      created_by_email_address: "test@example.com",
      display_priority: 5
    })

    # May 17-18, 2025 (Saturday-Sunday)
    Periods.create_period(%{
      is_valid_for_everybody: true,
      location_id: location_id,
      holiday_or_vacation_type_id: weekend_type.id,
      starts_on: ~D[2025-05-17],
      ends_on: ~D[2025-05-18],
      created_by_email_address: "test@example.com",
      display_priority: 5
    })

    # May 24-25, 2025 (Saturday-Sunday)
    Periods.create_period(%{
      is_valid_for_everybody: true,
      location_id: location_id,
      holiday_or_vacation_type_id: weekend_type.id,
      starts_on: ~D[2025-05-24],
      ends_on: ~D[2025-05-25],
      created_by_email_address: "test@example.com",
      display_priority: 5
    })

    # May 31-June 1, 2025 (Saturday-Sunday)
    Periods.create_period(%{
      is_valid_for_everybody: true,
      location_id: location_id,
      holiday_or_vacation_type_id: weekend_type.id,
      starts_on: ~D[2025-05-31],
      ends_on: ~D[2025-06-01],
      created_by_email_address: "test@example.com",
      display_priority: 5
    })
  end
end
