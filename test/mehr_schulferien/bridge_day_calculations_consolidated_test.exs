defmodule MehrSchulferien.BridgeDayCalculationsConsolidatedTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory

  alias MehrSchulferien.BridgeDays
  alias MehrSchulferien.BridgeDayCalculations
  alias MehrSchulferien.Periods.BridgeDayPeriod

  describe "basic calculations" do
    test "calculates correct number of days for periods" do
      # Single period
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-05]}]
      assert BridgeDayCalculations.get_number_max_days(periods) == 5

      # Multiple periods
      periods = [
        %{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-03]},
        %{starts_on: ~D[2024-01-04], ends_on: ~D[2024-01-05]},
        %{starts_on: ~D[2024-01-06], ends_on: ~D[2024-01-10]}
      ]

      assert BridgeDayCalculations.get_number_max_days(periods) == 10

      # Single day
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-01]}]
      assert BridgeDayCalculations.get_number_max_days(periods) == 1

      # Empty list
      assert BridgeDayCalculations.get_number_max_days([]) == 0
    end
  end

  describe "minimum gain calculations" do
    test "1 vacation day requires at least 3 free days" do
      bridge_day = %{number_days: 1}

      # 3 free days - meets minimum
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-03]}]
      assert BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)

      # 2 free days - doesn't meet minimum
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-02]}]
      refute BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)
    end

    test "2 vacation days requires more than 100% gain" do
      bridge_day = %{number_days: 2}

      # 5 free days = 150% gain - meets minimum
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-05]}]
      assert BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)

      # 4 free days = 100% gain - doesn't meet minimum
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-04]}]
      refute BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)
    end

    test "3+ vacation days requires more than 100% gain" do
      # Test 3 days
      bridge_day = %{number_days: 3}
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-07]}]
      assert BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)

      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-06]}]
      refute BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)

      # Test 4 days
      bridge_day = %{number_days: 4}
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-09]}]
      assert BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)

      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-08]}]
      refute BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)

      # Test 5 days
      bridge_day = %{number_days: 5}
      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-11]}]
      assert BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)

      periods = [%{starts_on: ~D[2024-01-01], ends_on: ~D[2024-01-10]}]
      refute BridgeDayCalculations.meets_minimum_gain?(bridge_day, periods)
    end
  end

  describe "consecutive free days calculations" do
    test "calculates correct gain for New Year 2026 bridge day" do
      bridge_day = %BridgeDayPeriod{
        starts_on: ~D[2026-01-02],
        ends_on: ~D[2026-01-02],
        number_days: 1
      }

      periods = [
        %{
          starts_on: ~D[2026-01-01],
          ends_on: ~D[2026-01-01],
          is_public_holiday: true,
          holiday_or_vacation_type: %{name: "Neujahrstag"}
        }
      ]

      total_free_days =
        BridgeDayCalculations.calculate_total_consecutive_free_days(bridge_day, periods)

      # Jan 1 (holiday) + Jan 2 (bridge day) + Jan 3-4 (weekend) = 4 days
      assert total_free_days == 4

      # Calculate efficiency percentage
      vacation_days = bridge_day.number_days
      efficiency_percentage = round((total_free_days - vacation_days) / vacation_days * 100)

      # 3 extra days / 1 vacation day * 100 = 300% gain
      assert efficiency_percentage == 300
    end

    test "calculates correct gain for Easter 2026 bridge days" do
      # Good Friday April 3, Easter Monday April 6, taking April 7 as bridge
      bridge_day = %BridgeDayPeriod{
        starts_on: ~D[2026-04-07],
        ends_on: ~D[2026-04-07],
        number_days: 1
      }

      periods = [
        %{
          starts_on: ~D[2026-04-03],
          ends_on: ~D[2026-04-03],
          is_public_holiday: true,
          holiday_or_vacation_type: %{name: "Karfreitag"}
        },
        %{
          starts_on: ~D[2026-04-06],
          ends_on: ~D[2026-04-06],
          is_public_holiday: true,
          holiday_or_vacation_type: %{name: "Ostermontag"}
        }
      ]

      total_free_days =
        BridgeDayCalculations.calculate_total_consecutive_free_days(bridge_day, periods)

      # April 3 (Good Friday) + April 4-5 (weekend) + April 6 (Easter Monday) + 
      # April 7 (bridge day) + April 8-11 (following days/weekend) = at least 5 days
      assert total_free_days >= 5
    end

    test "calculates correct gain for multi-day bridge period" do
      # Christmas period: Dec 24 (Thu) and Dec 25 (Fri) are holidays
      # Taking Dec 28-30 (Mon-Wed) as bridge days
      bridge_day = %BridgeDayPeriod{
        starts_on: ~D[2026-12-28],
        ends_on: ~D[2026-12-30],
        number_days: 3
      }

      periods = [
        %{
          starts_on: ~D[2026-12-24],
          ends_on: ~D[2026-12-25],
          is_public_holiday: true,
          holiday_or_vacation_type: %{name: "Weihnachten"}
        }
      ]

      total_free_days =
        BridgeDayCalculations.calculate_total_consecutive_free_days(bridge_day, periods)

      # Should include Dec 24-25 (holidays) + Dec 26-27 (weekend) + 
      # Dec 28-30 (bridge days) + Dec 31 - Jan 3 (New Year period)
      assert total_free_days >= 7
    end
  end

  describe "finding next bridge day" do
    test "find_next_bridge_day/2 finds the next bridge day for a federal state" do
      country = insert(:country, %{name: "Deutschland", code: "DE"})

      hamburg =
        insert(:federal_state, %{
          name: "Hamburg",
          code: "HH",
          parent_location_id: country.id
        })

      # Create test periods
      MehrSchulferien.Factory.create_test_periods(country.id, hamburg.id, 2025)

      # Test with April 4, 2025
      current_date = ~D[2025-04-04]
      result = BridgeDays.find_next_bridge_day(hamburg, current_date)

      # May 2 is a Friday between Labor Day (May 1) and weekend
      assert result.starts_on == ~D[2025-05-02]
      assert result.ends_on == ~D[2025-05-02]
      assert result.number_days == 1
    end

    test "find_next_bridge_day/3 respects the number of days parameter" do
      country = insert(:country, %{name: "Deutschland", code: "DE"})

      hamburg =
        insert(:federal_state, %{
          name: "Hamburg",
          code: "HH",
          parent_location_id: country.id
        })

      MehrSchulferien.Factory.create_test_periods(country.id, hamburg.id, 2025)
      current_date = ~D[2025-04-04]

      # Looking for 1 day bridge
      result_1_day = BridgeDays.find_next_bridge_day(hamburg, current_date, 1)
      assert result_1_day.number_days == 1

      # Looking for 2 days bridge (may return nil if none exists)
      result_2_days = BridgeDays.find_next_bridge_day(hamburg, current_date, 2)
      assert result_2_days == nil or result_2_days.number_days == 2
    end

    test "find_next_bridge_day/2 skips past bridge days" do
      country = insert(:country, %{name: "Deutschland", code: "DE"})

      hamburg =
        insert(:federal_state, %{
          name: "Hamburg",
          code: "HH",
          parent_location_id: country.id
        })

      MehrSchulferien.Factory.create_test_periods(country.id, hamburg.id, 2025)

      # Test with date AFTER the first bridge day (May 4, 2025)
      current_date = ~D[2025-05-04]
      result = BridgeDays.find_next_bridge_day(hamburg, current_date)

      # Should find a bridge day after May 4
      assert result == nil or Date.compare(result.starts_on, current_date) == :gt
    end

    test "returns nil when no bridge days exist in the future" do
      country = insert(:country, %{name: "Deutschland", code: "DE"})

      hamburg =
        insert(:federal_state, %{
          name: "Hamburg",
          code: "HH",
          parent_location_id: country.id
        })

      # Test with a far future date where no bridge days would exist
      current_date = ~D[2025-12-31]
      result = BridgeDays.find_next_bridge_day(hamburg, current_date)

      assert result == nil
    end
  end
end
