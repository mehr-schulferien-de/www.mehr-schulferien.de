defmodule MehrSchulferienWeb.VacationTimelineComponentTest do
  use MehrSchulferienWeb.ConnCase, async: true

  alias MehrSchulferienWeb.VacationTimelineComponent

  test "displays years only when multiple years are present in visible periods" do
    # Create test data
    today = ~D[2025-05-01]

    # Case 1: Periods with the same year (2025)
    single_year_periods = [
      %{
        starts_on: ~D[2025-05-29],
        ends_on: ~D[2025-05-29],
        holiday_or_vacation_type: %{name: "Christi Himmelfahrt"},
        is_public_holiday: true
      },
      %{
        starts_on: ~D[2025-06-09],
        ends_on: ~D[2025-06-09],
        holiday_or_vacation_type: %{name: "Pfingstmontag"},
        is_public_holiday: true
      },
      %{
        starts_on: ~D[2025-06-10],
        ends_on: ~D[2025-06-20],
        holiday_or_vacation_type: %{name: "Pfingsten"},
        is_school_vacation: true
      }
    ]

    # Case 2: Periods spanning multiple years (2025-2026)
    multi_year_periods = [
      %{
        starts_on: ~D[2025-12-24],
        ends_on: ~D[2025-12-24],
        holiday_or_vacation_type: %{name: "Heiligabend"},
        is_public_holiday: true
      },
      %{
        starts_on: ~D[2025-12-24],
        ends_on: ~D[2026-01-06],
        holiday_or_vacation_type: %{name: "Weihnachtsferien"},
        is_school_vacation: true
      }
    ]

    days_to_show = create_days(today, 90)
    months = get_test_months()

    # Test single year case
    html =
      VacationTimelineComponent.render(
        days_to_show: days_to_show,
        months: months,
        all_periods: single_year_periods,
        days_count: 90,
        months_with_days: [
          {"Mai", 31, 2025, 5},
          {"Juni", 30, 2025, 6},
          {"Juli", 29, 2025, 7}
        ]
      )
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    # For single year case: dates should NOT include years
    assert html =~ "(29.05.)"
    assert html =~ "(09.06.)"
    assert html =~ "(10.06. - 20.06.)"

    # Make sure years are NOT included for single year case
    refute html =~ "(29.05.2025)"
    refute html =~ "(09.06.2025)"
    refute html =~ "(10.06.2025 - 20.06.2025)"

    # Test multi-year case
    multi_year_html =
      VacationTimelineComponent.render(
        days_to_show: create_days(~D[2025-12-01], 90),
        months: months,
        all_periods: multi_year_periods,
        days_count: 90,
        months_with_days: [
          {"Dezember", 31, 2025, 12},
          {"Januar", 31, 2026, 1},
          {"Februar", 28, 2026, 2}
        ]
      )
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    # For multi year case: dates SHOULD include years
    assert multi_year_html =~ "(24.12.2025)"
    assert multi_year_html =~ "(24.12.2025 - 06.01.2026)"
  end

  # Helper functions
  defp create_days(start_date, count) do
    Enum.map(0..(count - 1), fn i -> Date.add(start_date, i) end)
  end

  defp get_test_months do
    %{
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
