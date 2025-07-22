defmodule MehrSchulferien.Helpers.DateParserTest do
  use ExUnit.Case, async: true

  alias MehrSchulferien.Helpers.DateParser

  describe "parse_dates/1" do
    test "parses single date" do
      assert {:ok, [~D[2026-02-16]]} = DateParser.parse_dates("16.02.2026")
      assert {:ok, [~D[2026-02-05]]} = DateParser.parse_dates("5.2.2026")
      assert {:ok, [~D[2026-12-31]]} = DateParser.parse_dates("31.12.2026")
    end

    test "parses date range" do
      assert {:ok, dates} = DateParser.parse_dates("16.-20.02.2026")

      assert dates == [
               ~D[2026-02-16],
               ~D[2026-02-17],
               ~D[2026-02-18],
               ~D[2026-02-19],
               ~D[2026-02-20]
             ]
    end

    test "parses multiple single dates" do
      assert {:ok, dates} = DateParser.parse_dates("16.02.2026, 18.03.2026")
      assert dates == [~D[2026-02-16], ~D[2026-03-18]]
    end

    test "parses mix of ranges and single dates" do
      assert {:ok, dates} = DateParser.parse_dates("16.02.2026, 18.-20.03.2026, 01.04.2026")

      assert dates == [
               ~D[2026-02-16],
               ~D[2026-03-18],
               ~D[2026-03-19],
               ~D[2026-03-20],
               ~D[2026-04-01]
             ]
    end

    test "handles empty input" do
      assert {:ok, []} = DateParser.parse_dates("")
      assert {:ok, []} = DateParser.parse_dates("   ")
    end

    test "returns error for invalid date format" do
      assert {:error, _} = DateParser.parse_dates("invalid")
      assert {:error, _} = DateParser.parse_dates("32.02.2026")
      assert {:error, _} = DateParser.parse_dates("16/02/2026")
    end

    test "returns error for invalid range" do
      assert {:error, _} = DateParser.parse_dates("20.-16.02.2026")
    end

    test "removes duplicates and sorts dates" do
      assert {:ok, dates} = DateParser.parse_dates("16.02.2026, 16.02.2026, 14.02.2026")
      assert dates == [~D[2026-02-14], ~D[2026-02-16]]
    end
  end

  describe "format_dates/1" do
    test "formats single date" do
      assert "16.02.2026" = DateParser.format_dates([~D[2026-02-16]])
    end

    test "formats consecutive dates as range" do
      dates = [~D[2026-02-16], ~D[2026-02-17], ~D[2026-02-18]]
      assert "16.-18.02.2026" = DateParser.format_dates(dates)
    end

    test "formats non-consecutive dates separately" do
      dates = [~D[2026-02-16], ~D[2026-03-18]]
      assert "16.02.2026, 18.03.2026" = DateParser.format_dates(dates)
    end

    test "formats mix of ranges and single dates" do
      dates = [
        ~D[2026-02-16],
        ~D[2026-02-17],
        ~D[2026-02-18],
        ~D[2026-03-20],
        ~D[2026-04-01]
      ]

      assert "16.-18.02.2026, 20.03.2026, 01.04.2026" = DateParser.format_dates(dates)
    end

    test "pads single digit days and months" do
      assert "05.02.2026" = DateParser.format_dates([~D[2026-02-05]])
      assert "16.09.2026" = DateParser.format_dates([~D[2026-09-16]])
    end
  end
end
