defmodule MehrSchulferienWeb.ViewHelpersTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferienWeb.ViewHelpers

  describe "returns number of days" do
    test "shows number of days for single period" do
      period = insert(:period, %{starts_on: ~D[2020-03-01], ends_on: ~D[2020-03-01]})
      assert ViewHelpers.number_days([period]) == 1
      period = insert(:period, %{starts_on: ~D[2020-03-01], ends_on: ~D[2020-03-07]})
      assert ViewHelpers.number_days([period]) == 7
    end

    test "shows combined number of days for multiple periods" do
      period_1 = insert(:period, %{starts_on: ~D[2020-03-01], ends_on: ~D[2020-03-04]})
      period_2 = insert(:period, %{starts_on: ~D[2020-03-21], ends_on: ~D[2020-03-22]})
      assert ViewHelpers.number_days([period_1, period_2]) == 6
    end
  end

  describe "format date range" do
    test "same date just shows one date" do
      assert ViewHelpers.format_date_range(~D[2020-04-06], ~D[2020-04-06]) == "6.4.20"
    end

    test "different dates show range" do
      assert ViewHelpers.format_date_range(~D[2020-04-06], ~D[2020-04-16]) ==
               "6.4. - 16.4.20"

      assert ViewHelpers.format_date_range(~D[2020-12-22], ~D[2021-01-10]) ==
               "22.12.20 - 10.1.21"
    end

    test "setting short value does not show year" do
      assert ViewHelpers.format_date_range(~D[2020-04-06], ~D[2020-04-06], :short) == "6.4."

      assert ViewHelpers.format_date_range(~D[2020-04-06], ~D[2020-04-16], :short) ==
               "6.4. - 16.4."
    end
  end

  describe "displays the year" do
    test "displays the first year in the list of periods" do
      period_1 = insert(:period, %{starts_on: ~D[2020-03-01], ends_on: ~D[2020-03-04]})
      period_2 = insert(:period, %{starts_on: ~D[2021-03-21], ends_on: ~D[2021-03-22]})
      assert ViewHelpers.display_year([[period_1, period_2], []]) == 2020
      assert ViewHelpers.display_year([[period_2], [period_1]]) == 2021
      assert ViewHelpers.display_year([[], [period_1, period_2]]) == 2020
    end
  end

  describe "gets the html_class" do
    test "shows html_class if date is a school vacation" do
      period =
        insert(:period, %{
          starts_on: ~D[2020-03-01],
          ends_on: ~D[2020-03-04],
          is_school_vacation: true
        })

      assert ViewHelpers.get_html_class(~D[2020-03-02], [period]) ==
               "bg-green-100 dark:bg-green-800"

      assert ViewHelpers.get_html_class(~D[2020-03-05], [period]) == ""
    end

    test "get_html_class/2 shows period with highest display_priority" do
      period_1 =
        insert(:period, %{
          display_priority: 8,
          starts_on: ~D[2020-03-01],
          ends_on: ~D[2020-03-01],
          is_public_holiday: true
        })

      period_2 =
        insert(:period, %{
          display_priority: 5,
          starts_on: ~D[2020-03-01],
          ends_on: ~D[2020-03-04],
          is_school_vacation: true
        })

      # Period 1 has higher priority (8 > 5) and is a holiday (blue)
      assert ViewHelpers.get_html_class(~D[2020-03-01], [period_1, period_2]) ==
               "bg-blue-100 dark:bg-blue-800"

      assert ViewHelpers.get_html_class(~D[2020-03-02], [period_1, period_2]) ==
               "bg-green-100 dark:bg-green-800"
    end
  end

  describe "format_number/1" do
    test "formats large numbers with thousand separators" do
      assert ViewHelpers.format_number(1_234_567) == "1.234.567"
      assert ViewHelpers.format_number(1_000_000) == "1.000.000"
      assert ViewHelpers.format_number(99999) == "99.999"
    end

    test "formats small numbers without separators" do
      assert ViewHelpers.format_number(123) == "123"
      assert ViewHelpers.format_number(99) == "99"
      assert ViewHelpers.format_number(1) == "1"
    end

    test "formats numbers at thousand boundaries" do
      assert ViewHelpers.format_number(1000) == "1.000"
      assert ViewHelpers.format_number(1234) == "1.234"
      assert ViewHelpers.format_number(10000) == "10.000"
    end

    test "handles nil gracefully" do
      assert ViewHelpers.format_number(nil) == ""
    end

    test "handles floats by rounding" do
      assert ViewHelpers.format_number(1234.56) == "1.235"
      assert ViewHelpers.format_number(999.99) == "1.000"
      assert ViewHelpers.format_number(1000.1) == "1.000"
    end

    test "handles string numbers" do
      assert ViewHelpers.format_number("1234567") == "1.234.567"
      assert ViewHelpers.format_number("1000") == "1.000"
      assert ViewHelpers.format_number("invalid") == ""
    end

    test "handles zero" do
      assert ViewHelpers.format_number(0) == "0"
    end

    test "handles negative numbers" do
      assert ViewHelpers.format_number(-1234) == "-1.234"
      assert ViewHelpers.format_number(-1_234_567) == "-1.234.567"
    end
  end
end
