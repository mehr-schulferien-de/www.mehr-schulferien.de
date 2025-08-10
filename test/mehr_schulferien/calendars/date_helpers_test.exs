defmodule MehrSchulferien.Calendars.DateHelpersTest do
  use ExUnit.Case, async: true

  alias MehrSchulferien.Calendars.DateHelpers

  describe "today_berlin/0" do
    test "returns a date" do
      date = DateHelpers.today_berlin()
      assert %Date{} = date
    end
  end

  describe "get_today_or_custom_date/1" do
    test "returns custom date from conn when available" do
      custom_date = ~D[2025-01-01]
      conn = %{assigns: %{custom_date: custom_date}}

      assert DateHelpers.get_today_or_custom_date(conn) == custom_date
    end

    test "returns today's date when conn has no custom_date" do
      conn = %{assigns: %{}}
      result = DateHelpers.get_today_or_custom_date(conn)

      assert %Date{} = result
    end

    test "returns today's date when conn.assigns.custom_date is nil" do
      conn = %{assigns: %{custom_date: nil}}
      result = DateHelpers.get_today_or_custom_date(conn)

      assert %Date{} = result
    end

    test "returns today's date when no conn is passed" do
      result = DateHelpers.get_today_or_custom_date()
      assert %Date{} = result
    end

    test "returns today's date when conn is nil" do
      result = DateHelpers.get_today_or_custom_date(nil)
      assert %Date{} = result
    end
  end

  describe "create_3_years/1" do
    test "creates dates for 3 consecutive years" do
      result = DateHelpers.create_3_years(2024)

      # Should have 3 years × 12 months = 36 lists
      assert length(result) == 36

      # Check first and last months
      [january_2024 | _] = result
      assert List.first(january_2024) == ~D[2024-01-01]

      december_2026 = List.last(result)
      assert List.last(december_2026) == ~D[2026-12-31]
    end
  end

  describe "create_year/1" do
    test "creates 12 months of dates for a year" do
      result = DateHelpers.create_year(2024)

      assert length(result) == 12

      # Check each month
      Enum.with_index(result, 1)
      |> Enum.each(fn {month_dates, month_num} ->
        first_date = List.first(month_dates)
        assert first_date.month == month_num
        assert first_date.year == 2024
      end)
    end
  end

  describe "create_month/2" do
    test "creates correct number of days for January" do
      result = DateHelpers.create_month(2024, 1)
      assert length(result) == 31
      assert List.first(result) == ~D[2024-01-01]
      assert List.last(result) == ~D[2024-01-31]
    end

    test "creates correct number of days for February in non-leap year" do
      result = DateHelpers.create_month(2023, 2)
      assert length(result) == 28
    end

    test "creates correct number of days for February in leap year" do
      result = DateHelpers.create_month(2024, 2)
      assert length(result) == 29
    end

    test "creates correct number of days for April (30 days)" do
      result = DateHelpers.create_month(2024, 4)
      assert length(result) == 30
    end

    test "handles month numbers greater than 12" do
      # Month 13 should be normalized to next year's January
      result = DateHelpers.create_month(2024, 13)
      assert length(result) == 31
      # The function should normalize month 13 to January of the next year
      first_date = List.first(result)
      assert first_date.year == 2025
      assert first_date.month == 1
      assert first_date.day == 1
    end
  end

  describe "create_days/2" do
    test "creates specified number of consecutive days" do
      start_date = ~D[2024-01-15]
      result = DateHelpers.create_days(start_date, 5)

      assert length(result) == 5

      assert result == [
               ~D[2024-01-15],
               ~D[2024-01-16],
               ~D[2024-01-17],
               ~D[2024-01-18],
               ~D[2024-01-19]
             ]
    end

    test "handles nil date with valid number of days" do
      result = DateHelpers.create_days(nil, 3)
      assert length(result) == 3
      assert %Date{} = List.first(result)
    end

    test "handles valid date with nil number of days (defaults to 90)" do
      result = DateHelpers.create_days(~D[2024-01-01], nil)
      assert length(result) == 90
    end

    test "handles both parameters being nil" do
      result = DateHelpers.create_days(nil, nil)
      assert length(result) == 90
      assert %Date{} = List.first(result)
    end

    test "handles invalid number of days" do
      result = DateHelpers.create_days(~D[2024-01-01], -5)
      assert length(result) == 90
    end

    test "handles zero days" do
      result = DateHelpers.create_days(~D[2024-01-01], 0)
      assert length(result) == 90
    end
  end

  describe "short_days_map/0" do
    test "returns correct German abbreviated day names" do
      result = DateHelpers.short_days_map()

      assert result == %{
               1 => "Mo",
               2 => "Di",
               3 => "Mi",
               4 => "Do",
               5 => "Fr",
               6 => "Sa",
               7 => "So"
             }
    end
  end

  describe "weekday/2" do
    test "returns full German weekday names by default" do
      assert DateHelpers.weekday(1) == "Montag"
      assert DateHelpers.weekday(2) == "Dienstag"
      assert DateHelpers.weekday(3) == "Mittwoch"
      assert DateHelpers.weekday(4) == "Donnerstag"
      assert DateHelpers.weekday(5) == "Freitag"
      assert DateHelpers.weekday(6) == "Samstag"
      assert DateHelpers.weekday(7) == "Sonntag"
    end

    test "returns short German weekday names without dot" do
      assert DateHelpers.weekday(1, :short) == "Mo"
      assert DateHelpers.weekday(2, :short) == "Di"
      assert DateHelpers.weekday(3, :short) == "Mi"
      assert DateHelpers.weekday(4, :short) == "Do"
      assert DateHelpers.weekday(5, :short) == "Fr"
      assert DateHelpers.weekday(6, :short) == "Sa"
      assert DateHelpers.weekday(7, :short) == "So"
    end

    test "returns short German weekday names with dot" do
      assert DateHelpers.weekday(1, :short_with_dot) == "Mo."
      assert DateHelpers.weekday(2, :short_with_dot) == "Di."
      assert DateHelpers.weekday(3, :short_with_dot) == "Mi."
      assert DateHelpers.weekday(4, :short_with_dot) == "Do."
      assert DateHelpers.weekday(5, :short_with_dot) == "Fr."
      assert DateHelpers.weekday(6, :short_with_dot) == "Sa."
      assert DateHelpers.weekday(7, :short_with_dot) == "So."
    end
  end

  describe "get_months_map/0" do
    test "returns correct German month names" do
      result = DateHelpers.get_months_map()

      assert result == %{
               1 => "Januar",
               2 => "Februar",
               3 => "März",
               4 => "April",
               5 => "Mai",
               6 => "Juni",
               7 => "Juli",
               8 => "August",
               9 => "September",
               10 => "Oktober",
               11 => "November",
               12 => "Dezember"
             }
    end
  end

  describe "compare_by_month/2" do
    test "returns :eq for same month and year" do
      date1 = ~D[2024-03-15]
      date2 = ~D[2024-03-25]

      assert DateHelpers.compare_by_month(date1, date2) == :eq
    end

    test "returns :gt when first date has later month in same year" do
      date1 = ~D[2024-05-01]
      date2 = ~D[2024-03-01]

      assert DateHelpers.compare_by_month(date1, date2) == :gt
    end

    test "returns :lt when first date has earlier month in same year" do
      date1 = ~D[2024-03-01]
      date2 = ~D[2024-05-01]

      assert DateHelpers.compare_by_month(date1, date2) == :lt
    end

    test "returns :gt when first date has later year" do
      date1 = ~D[2025-01-01]
      date2 = ~D[2024-12-31]

      assert DateHelpers.compare_by_month(date1, date2) == :gt
    end

    test "returns :lt when first date has earlier year" do
      date1 = ~D[2023-12-31]
      date2 = ~D[2024-01-01]

      assert DateHelpers.compare_by_month(date1, date2) == :lt
    end
  end

  describe "leap year handling" do
    test "recognizes configured leap years" do
      # Test known leap years
      assert length(DateHelpers.create_month(2020, 2)) == 29
      assert length(DateHelpers.create_month(2024, 2)) == 29
      assert length(DateHelpers.create_month(2028, 2)) == 29

      # Test non-leap year
      assert length(DateHelpers.create_month(2023, 2)) == 28
    end
  end
end
