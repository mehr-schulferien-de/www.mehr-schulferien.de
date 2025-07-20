defmodule MehrSchulferienWeb.Formatters.DateFormatterTest do
  use ExUnit.Case, async: true

  alias MehrSchulferienWeb.Formatters.DateFormatter

  describe "format_date_short/1" do
    test "formats date in DD.MM. format" do
      assert DateFormatter.format_date_short(~D[2024-01-15]) == "15.01."
      assert DateFormatter.format_date_short(~D[2024-12-31]) == "31.12."
      assert DateFormatter.format_date_short(~D[2024-07-04]) == "04.07."
    end

    test "returns empty string for nil" do
      assert DateFormatter.format_date_short(nil) == ""
    end
  end

  describe "format_date_full/1" do
    test "formats date in DD.MM.YYYY format" do
      assert DateFormatter.format_date_full(~D[2024-01-15]) == "15.01.2024"
      assert DateFormatter.format_date_full(~D[2024-12-31]) == "31.12.2024"
      assert DateFormatter.format_date_full(~D[2024-07-04]) == "04.07.2024"
    end

    test "returns empty string for nil" do
      assert DateFormatter.format_date_full(nil) == ""
    end
  end

  describe "format_date_with_short_year/1" do
    test "formats date with two-digit year" do
      assert DateFormatter.format_date_with_short_year(~D[2024-01-15]) == "15.01.24"
      assert DateFormatter.format_date_with_short_year(~D[2025-12-31]) == "31.12.25"
      assert DateFormatter.format_date_with_short_year(~D[2000-01-01]) == "01.01.00"
    end
  end

  describe "format_datetime/1" do
    test "formats DateTime with Berlin timezone" do
      # UTC datetime that becomes 15:30 in Berlin (UTC+1 in winter)
      utc_datetime = ~U[2024-01-15 14:30:00Z]
      assert DateFormatter.format_datetime(utc_datetime) == "15.01.2024 15:30:00 Uhr"
    end

    test "formats NaiveDateTime assuming UTC" do
      naive_datetime = ~N[2024-01-15 14:30:00]
      assert DateFormatter.format_datetime(naive_datetime) == "15.01.2024 15:30:00 Uhr"
    end
  end

  describe "format_date_range/3" do
    test "formats same date" do
      date = ~D[2024-01-15]
      assert DateFormatter.format_date_range(date, date, :short) == "15.01."
      assert DateFormatter.format_date_range(date, date, nil) == "15.01.24"
    end

    test "formats date range in same year" do
      from_date = ~D[2024-01-15]
      till_date = ~D[2024-01-20]

      assert DateFormatter.format_date_range(from_date, till_date, :short) == "15.01. - 20.01."
      assert DateFormatter.format_date_range(from_date, till_date, nil) == "15.01. - 20.01.24"
    end

    test "formats date range across years" do
      from_date = ~D[2023-12-20]
      till_date = ~D[2024-01-10]

      assert DateFormatter.format_date_range(from_date, till_date, :short) == "20.12. - 10.01."
      assert DateFormatter.format_date_range(from_date, till_date, nil) == "20.12.23 - 10.01.24"
    end
  end

  describe "format_date_ical/1" do
    test "formats date in iCal format YYYYMMDD" do
      assert DateFormatter.format_date_ical(~D[2024-01-15]) == "20240115"
      assert DateFormatter.format_date_ical(~D[2024-12-31]) == "20241231"
      assert DateFormatter.format_date_ical(~D[2024-07-04]) == "20240704"
    end
  end

  describe "format_next_day_ical/1" do
    test "formats the next day in iCal format" do
      assert DateFormatter.format_next_day_ical(~D[2024-01-15]) == "20240116"
      assert DateFormatter.format_next_day_ical(~D[2024-12-31]) == "20250101"
      # Leap year
      assert DateFormatter.format_next_day_ical(~D[2024-02-28]) == "20240229"
    end
  end
end
