defmodule MehrSchulferien.PeriodDisplayTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory

  alias MehrSchulferien.PeriodDisplay

  describe "get_school_period/1" do
    test "returns nil when no school vacation periods" do
      periods = [
        build(:period, is_school_vacation: false),
        build(:period, is_school_vacation: false)
      ]

      assert PeriodDisplay.get_school_period(periods) == nil
    end

    test "returns the period when only one school vacation period exists" do
      period = build(:period, is_school_vacation: true)

      periods = [
        build(:period, is_school_vacation: false),
        period,
        build(:period, is_school_vacation: false)
      ]

      assert PeriodDisplay.get_school_period(periods) == period
    end

    test "returns the period with highest display_priority when multiple school vacation periods exist" do
      period1 = build(:period, is_school_vacation: true, display_priority: 1)
      period2 = build(:period, is_school_vacation: true, display_priority: 3)
      period3 = build(:period, is_school_vacation: true, display_priority: 2)

      periods = [period1, period2, period3]

      assert PeriodDisplay.get_school_period(periods) == period2
    end
  end

  describe "select_display_period/1" do
    test "returns the period with the highest display_priority" do
      period1 = build(:period, display_priority: 1)
      period2 = build(:period, display_priority: 5)
      period3 = build(:period, display_priority: 3)

      assert PeriodDisplay.select_display_period([period1, period2, period3]) == period2
    end

    test "handles single period" do
      period = build(:period, display_priority: 1)
      assert PeriodDisplay.select_display_period([period]) == period
    end
  end

  describe "display_period_info?/3" do
    test "returns false when period is nil" do
      assert PeriodDisplay.display_period_info?(~D[2024-01-01], [~D[2024-01-01]], nil) == false
    end

    test "returns true for school vacation when date is first in dates list" do
      period = build(:period, is_school_vacation: true, starts_on: ~D[2024-01-05])
      dates = [~D[2024-01-01], ~D[2024-01-02], ~D[2024-01-03]]

      assert PeriodDisplay.display_period_info?(~D[2024-01-01], dates, period) == true
    end

    test "returns true for school vacation when date equals period start date" do
      period = build(:period, is_school_vacation: true, starts_on: ~D[2024-01-05])
      dates = [~D[2024-01-01], ~D[2024-01-02], ~D[2024-01-05]]

      assert PeriodDisplay.display_period_info?(~D[2024-01-05], dates, period) == true
    end

    test "returns false for school vacation when date is neither first nor period start" do
      period = build(:period, is_school_vacation: true, starts_on: ~D[2024-01-05])
      dates = [~D[2024-01-01], ~D[2024-01-02], ~D[2024-01-03]]

      assert PeriodDisplay.display_period_info?(~D[2024-01-02], dates, period) == false
    end

    test "returns nil for non-school vacation period" do
      period = build(:period, is_school_vacation: false, starts_on: ~D[2024-01-05])
      dates = [~D[2024-01-01], ~D[2024-01-02], ~D[2024-01-03]]

      assert PeriodDisplay.display_period_info?(~D[2024-01-01], dates, period) == nil
    end
  end

  describe "get_period_colspan/3" do
    test "calculates colspan when period ends before last_date" do
      period = build(:period, ends_on: ~D[2024-01-05])

      assert PeriodDisplay.get_period_colspan(~D[2024-01-01], ~D[2024-01-10], period) == 5
    end

    test "calculates colspan when period ends after last_date" do
      period = build(:period, ends_on: ~D[2024-01-15])

      assert PeriodDisplay.get_period_colspan(~D[2024-01-01], ~D[2024-01-10], period) == 10
    end

    test "calculates colspan for single day" do
      period = build(:period, ends_on: ~D[2024-01-01])

      assert PeriodDisplay.get_period_colspan(~D[2024-01-01], ~D[2024-01-10], period) == 1
    end
  end

  describe "show_period_info/2" do
    test "displays full info when enough space" do
      holiday_type = build(:holiday_or_vacation_type, colloquial: "Summer")

      period =
        build(:period,
          holiday_or_vacation_type: holiday_type,
          starts_on: ~D[2024-07-01],
          ends_on: ~D[2024-08-31]
        )

      # Mock ViewHelpers.format_date_range to return a consistent value
      # Note: In a real test, you might want to use Mox or similar for this
      # For now, we'll test the string manipulation logic
      result = PeriodDisplay.show_period_info(period, 20)

      assert String.contains?(result, "Summer")
    end

    test "displays only name when limited space" do
      holiday_type = build(:holiday_or_vacation_type, colloquial: "Christmas Holiday")
      period = build(:period, holiday_or_vacation_type: holiday_type)

      result = PeriodDisplay.show_period_info(period, 5)

      assert result == "Christmas Holiday"
    end

    test "truncates name when very limited space" do
      holiday_type = build(:holiday_or_vacation_type, colloquial: "VeryLongHolidayName")
      period = build(:period, holiday_or_vacation_type: holiday_type)

      result = PeriodDisplay.show_period_info(period, 2)

      assert result == "VeryLong"
    end
  end

  describe "get_non_school_period/3" do
    test "returns nil when no non-school periods exist" do
      periods = [
        build(:period, is_school_vacation: true),
        build(:period, is_school_vacation: true)
      ]

      assert PeriodDisplay.get_non_school_period(~D[2024-01-01], nil, periods) == nil
    end

    test "returns weekend period" do
      holiday_type = build(:holiday_or_vacation_type, name: "Wochenende")

      weekend_period =
        build(:period,
          holiday_or_vacation_type: holiday_type,
          is_school_vacation: true
        )

      periods = [
        build(:period, is_school_vacation: true),
        weekend_period
      ]

      assert PeriodDisplay.get_non_school_period(~D[2024-01-01], nil, periods) == weekend_period
    end

    test "returns non-school vacation period" do
      non_school_period = build(:period, is_school_vacation: false)

      periods = [
        build(:period, is_school_vacation: true),
        non_school_period
      ]

      assert PeriodDisplay.get_non_school_period(~D[2024-01-01], nil, periods) ==
               non_school_period
    end

    test "selects period with highest priority when multiple non-school periods" do
      holiday_type = build(:holiday_or_vacation_type, name: "Wochenende")

      period1 =
        build(:period,
          holiday_or_vacation_type: holiday_type,
          display_priority: 1
        )

      period2 = build(:period, is_school_vacation: false, display_priority: 3)
      period3 = build(:period, is_school_vacation: false, display_priority: 2)

      periods = [period1, period2, period3]

      assert PeriodDisplay.get_non_school_period(~D[2024-01-01], nil, periods) == period2
    end

    test "returns nil when date is within existing period's range" do
      period = build(:period, ends_on: ~D[2024-01-10])
      periods = []

      assert PeriodDisplay.get_non_school_period(~D[2024-01-05], period, periods) == nil
    end

    test "checks for new period when date is after existing period" do
      existing_period = build(:period, ends_on: ~D[2024-01-05])
      new_period = build(:period, is_school_vacation: false)
      periods = [new_period]

      assert PeriodDisplay.get_non_school_period(~D[2024-01-10], existing_period, periods) ==
               new_period
    end
  end
end
