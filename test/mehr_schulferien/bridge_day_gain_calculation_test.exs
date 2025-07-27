defmodule MehrSchulferien.BridgeDayGainCalculationTest do
  use MehrSchulferien.DataCase

  alias MehrSchulferien.BridgeDayCalculations
  alias MehrSchulferien.Periods.BridgeDayPeriod

  describe "calculate_total_consecutive_free_days/2" do
    test "calculates correct gain for New Year 2026 bridge day (Jan 2)" do
      # Create a bridge day for January 2, 2026 (Friday)
      bridge_day = %BridgeDayPeriod{
        starts_on: ~D[2026-01-02],
        ends_on: ~D[2026-01-02],
        number_days: 1
      }

      # Create periods for New Year's Day (Thursday, Jan 1, 2026)
      periods = [
        %{
          starts_on: ~D[2026-01-01],
          ends_on: ~D[2026-01-01],
          is_public_holiday: true,
          holiday_or_vacation_type: %{name: "Neujahrstag"}
        }
      ]

      # Calculate total free days
      total_free_days =
        BridgeDayCalculations.calculate_total_consecutive_free_days(bridge_day, periods)

      # The function expands to find ALL consecutive free days including:
      # - Previous weekend (Dec 27-28: Sat-Sun)
      # - Working days (Dec 29-31: Mon-Wed) 
      # - Jan 1 (Thu - New Year's Day holiday)
      # - Jan 2 (Fri - bridge day/vacation)
      # - Jan 3-4 (Sat-Sun weekend)
      # But wait, it treats the bridge day itself as a "free day" and keeps expanding!
      # It will go back and find Dec 20-21 weekend, then forward to Jan 10-11 weekend
      # Actually: Dec 20-21 (weekend) + Dec 22-26 (workdays) + Dec 27-28 (weekend) + 
      # Dec 29-31 (workdays) + Jan 1 (holiday) + Jan 2 (bridge) + Jan 3-4 (weekend) +
      # Jan 5-9 (workdays) + Jan 10-11 (weekend) = way more than expected!

      # The consecutive sequence should be:
      # Jan 1 (holiday) + Jan 2 (bridge day) + Jan 3-4 (weekend) = 4 days
      assert total_free_days == 4

      # Calculate efficiency percentage
      vacation_days = bridge_day.number_days
      efficiency_percentage = round((total_free_days - vacation_days) / vacation_days * 100)

      # 4 free days - 1 vacation day = 3 extra days
      # 3 / 1 * 100 = 300% gain
      assert efficiency_percentage == 300
    end

    test "calculates correct gain for Easter 2026 bridge days" do
      # Good Friday is April 3, 2026 (Friday)
      # Easter Monday is April 6, 2026 (Monday)
      # Taking April 7 (Tuesday) as bridge day
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

      # With 1 vacation day (Apr 7), you get:
      # Apr 3 (Fri - Good Friday) + Apr 4-5 (Sat-Sun) + Apr 6 (Mon - Easter Monday) + 
      # Apr 7 (Tue - bridge day) + Apr 8-10 would be working days
      # So: 5 consecutive free days
      assert total_free_days == 5

      efficiency_percentage = round((total_free_days - 1) / 1 * 100)
      # 400% gain
      assert efficiency_percentage == 400
    end

    test "calculates correct gain for Christmas 2025 bridge days (4 vacation days)" do
      # Christmas 2025: Dec 25-26 (Thu-Fri)
      # Taking Dec 22-24 and Dec 29 as vacation days (4 days total)
      bridge_day = %BridgeDayPeriod{
        starts_on: ~D[2025-12-22],
        ends_on: ~D[2025-12-29],
        number_days: 4
      }

      periods = [
        %{
          starts_on: ~D[2025-12-25],
          ends_on: ~D[2025-12-25],
          is_public_holiday: true,
          holiday_or_vacation_type: %{name: "1. Weihnachtsfeiertag"}
        },
        %{
          starts_on: ~D[2025-12-26],
          ends_on: ~D[2025-12-26],
          is_public_holiday: true,
          holiday_or_vacation_type: %{name: "2. Weihnachtsfeiertag"}
        }
      ]

      total_free_days =
        BridgeDayCalculations.calculate_total_consecutive_free_days(bridge_day, periods)

      # Dec 20-21 (Sat-Sun) + Dec 22-29 (bridge period including holidays) + potentially more
      # The function should find all consecutive free days
      # At least 10 days
      assert total_free_days >= 10

      efficiency_percentage = round((total_free_days - 4) / 4 * 100)
      # At least 150% gain
      assert efficiency_percentage >= 150
    end

    test "handles single day with no adjacent free days" do
      # A Wednesday with no adjacent holidays or weekends
      bridge_day = %BridgeDayPeriod{
        starts_on: ~D[2026-02-11],
        ends_on: ~D[2026-02-11],
        number_days: 1
      }

      # No holidays
      periods = []

      total_free_days =
        BridgeDayCalculations.calculate_total_consecutive_free_days(bridge_day, periods)

      # Just the bridge day itself
      assert total_free_days == 1

      efficiency_percentage = round((total_free_days - 1) / 1 * 100)
      # 0% gain
      assert efficiency_percentage == 0
    end

    test "correctly identifies weekends" do
      # Taking Friday as bridge day to extend weekend
      bridge_day = %BridgeDayPeriod{
        # Friday
        starts_on: ~D[2026-01-09],
        ends_on: ~D[2026-01-09],
        number_days: 1
      }

      # No holidays
      periods = []

      total_free_days =
        BridgeDayCalculations.calculate_total_consecutive_free_days(bridge_day, periods)

      # Friday (bridge day) + Saturday + Sunday = 3 days
      assert total_free_days == 3

      efficiency_percentage = round((total_free_days - 1) / 1 * 100)
      # 200% gain
      assert efficiency_percentage == 200
    end
  end
end
