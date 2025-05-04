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
        holiday_or_vacation_type: %{
          name: "Christi Himmelfahrt",
          colloquial: "Christi Himmelfahrt"
        },
        is_public_holiday: true
      },
      %{
        starts_on: ~D[2025-06-09],
        ends_on: ~D[2025-06-09],
        holiday_or_vacation_type: %{
          name: "Pfingstmontag",
          colloquial: "Pfingstmontag"
        },
        is_public_holiday: true
      },
      %{
        starts_on: ~D[2025-06-10],
        ends_on: ~D[2025-06-20],
        holiday_or_vacation_type: %{name: "Pfingstferien", colloquial: "Pfingstferien"},
        is_school_vacation: true
      }
    ]

    # Case 2: Periods spanning multiple years (2025-2026)
    multi_year_periods = [
      %{
        starts_on: ~D[2025-12-24],
        ends_on: ~D[2025-12-24],
        holiday_or_vacation_type: %{name: "Heiligabend", colloquial: "Heiligabend"},
        is_public_holiday: true
      },
      %{
        starts_on: ~D[2025-12-24],
        ends_on: ~D[2026-01-06],
        holiday_or_vacation_type: %{name: "Weihnachtsferien", colloquial: "Weihnachtsferien"},
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

  test "displays countdown to next vacation" do
    # Create fixed date for tests
    current_date = ~D[2025-05-15]

    # Define vacation periods
    vacation_periods = [
      %{
        starts_on: ~D[2025-05-29],
        ends_on: ~D[2025-05-29],
        holiday_or_vacation_type: %{
          name: "Christi Himmelfahrt",
          colloquial: "Christi Himmelfahrt"
        },
        is_public_holiday: true
      },
      %{
        starts_on: ~D[2025-06-10],
        ends_on: ~D[2025-06-20],
        holiday_or_vacation_type: %{name: "Pfingstferien", colloquial: "Pfingstferien"},
        is_school_vacation: true
      },
      %{
        starts_on: ~D[2025-07-30],
        ends_on: ~D[2025-09-10],
        holiday_or_vacation_type: %{name: "Sommerferien", colloquial: "Sommerferien"},
        is_school_vacation: true
      }
    ]

    # Create component and manually add the next vacation and days_until values
    days_to_show = create_days(current_date, 90)
    months = get_test_months()

    # Calculate expected days until next vacation
    expected_days_until = Date.diff(~D[2025-06-10], current_date)

    html =
      VacationTimelineComponent.render(%{
        days_to_show: days_to_show,
        months: months,
        all_periods: vacation_periods,
        days_count: 90,
        months_with_days: [
          {"Mai", 31, 2025, 5},
          {"Juni", 30, 2025, 6},
          {"Juli", 29, 2025, 7}
        ],
        # Override the Date.utc_today() with our fixed date for testing
        _test_today: current_date
      })
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    # Assert that the countdown is shown correctly (26 days from May 15 to June 10)
    assert html =~ "Noch #{expected_days_until} Tage bis Pfingstferien."

    # Should not display countdown to public holidays
    refute html =~ "Tage bis Christi Himmelfahrt"
  end

  test "uses timeline start date as reference date for countdown" do
    # Define vacation periods - Pfingstferien starts 40 days after timeline start
    timeline_start_date = ~D[2025-05-01]
    vacation_start_date = ~D[2025-06-10]

    vacation_periods = [
      %{
        starts_on: vacation_start_date,
        ends_on: ~D[2025-06-20],
        holiday_or_vacation_type: %{name: "Pfingstferien", colloquial: "Pfingstferien"},
        is_school_vacation: true
      }
    ]

    # Create timeline data
    days_to_show = create_days(timeline_start_date, 90)
    months = get_test_months()

    # Calculate expected days until vacation
    expected_days_until = Date.diff(vacation_start_date, timeline_start_date)

    html =
      VacationTimelineComponent.render(%{
        days_to_show: days_to_show,
        months: months,
        all_periods: vacation_periods,
        days_count: 90,
        months_with_days: [
          {"Mai", 31, 2025, 5},
          {"Juni", 30, 2025, 6},
          {"Juli", 29, 2025, 7}
        ]
      })
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    # Assert countdown uses timeline start date (May 1) as reference
    # (40 days from May 1 to June 10)
    assert html =~ "Noch #{expected_days_until} Tage bis Pfingstferien."
  end

  test "displays special message when reference date is within a vacation period" do
    # Create a vacation period
    vacation_start = ~D[2025-07-30]
    vacation_end = ~D[2025-09-10]
    # Middle of the vacation
    reference_date = ~D[2025-08-15]

    vacation_periods = [
      %{
        starts_on: vacation_start,
        ends_on: vacation_end,
        holiday_or_vacation_type: %{name: "Sommerferien", colloquial: "Sommerferien"},
        is_school_vacation: true
      }
    ]

    # Create timeline data
    days_to_show = create_days(reference_date, 90)
    months = get_test_months()

    # Calculate expected days remaining in vacation
    expected_days_remaining = Date.diff(vacation_end, reference_date)

    html =
      VacationTimelineComponent.render(%{
        days_to_show: days_to_show,
        months: months,
        all_periods: vacation_periods,
        days_count: 90,
        months_with_days: [
          {"August", 31, 2025, 8},
          {"September", 30, 2025, 9},
          {"Oktober", 31, 2025, 10}
        ],
        _test_today: reference_date
      })
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    # Should show message about current vacation
    assert html =~ "Aktuell sind Sommerferien (noch #{expected_days_remaining} Tage)."

    # Should not show countdown to next vacation
    refute html =~ "Noch"
    refute html =~ "Tage bis"
  end

  test "displays 'letzter Tag' message on the last day of vacation" do
    # Create a vacation period
    vacation_start = ~D[2025-07-30]
    vacation_end = ~D[2025-09-10]
    # Last day of vacation
    reference_date = vacation_end

    vacation_periods = [
      %{
        starts_on: vacation_start,
        ends_on: vacation_end,
        holiday_or_vacation_type: %{name: "Sommerferien", colloquial: "Sommerferien"},
        is_school_vacation: true
      }
    ]

    # Create timeline data
    days_to_show = create_days(reference_date, 90)
    months = get_test_months()

    html =
      VacationTimelineComponent.render(%{
        days_to_show: days_to_show,
        months: months,
        all_periods: vacation_periods,
        days_count: 90,
        months_with_days: [
          {"September", 30, 2025, 9},
          {"Oktober", 31, 2025, 10},
          {"November", 30, 2025, 11}
        ],
        _test_today: reference_date
      })
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    # Should show message about last day of vacation
    assert html =~ "Aktuell sind Sommerferien (letzter Tag)."
  end

  test "prefers colloquial name over formal name" do
    # Create fixed date for tests
    current_date = ~D[2025-05-15]

    # Define vacation periods with different colloquial names
    vacation_periods = [
      %{
        starts_on: ~D[2025-06-10],
        ends_on: ~D[2025-06-20],
        holiday_or_vacation_type: %{name: "Pfingstferien", colloquial: "Ferien zu Pfingsten"},
        is_school_vacation: true
      }
    ]

    days_to_show = create_days(current_date, 90)
    months = get_test_months()

    html =
      VacationTimelineComponent.render(%{
        days_to_show: days_to_show,
        months: months,
        all_periods: vacation_periods,
        days_count: 90,
        months_with_days: [
          {"Mai", 31, 2025, 5},
          {"Juni", 30, 2025, 6},
          {"Juli", 29, 2025, 7}
        ],
        _test_today: current_date
      })
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    # Should use colloquial name
    assert html =~ "Ferien zu Pfingsten"

    # Should not use formal name
    refute html =~ "Pfingstferien"
  end

  test "falls back to name when colloquial is not available" do
    # Create fixed date for tests
    current_date = ~D[2025-05-15]

    # Define vacation period without colloquial name
    vacation_periods = [
      %{
        starts_on: ~D[2025-06-10],
        ends_on: ~D[2025-06-20],
        # No colloquial name
        holiday_or_vacation_type: %{name: "Pfingstferien"},
        is_school_vacation: true
      }
    ]

    days_to_show = create_days(current_date, 90)
    months = get_test_months()

    html =
      VacationTimelineComponent.render(%{
        days_to_show: days_to_show,
        months: months,
        all_periods: vacation_periods,
        days_count: 90,
        months_with_days: [
          {"Mai", 31, 2025, 5},
          {"Juni", 30, 2025, 6},
          {"Juli", 29, 2025, 7}
        ],
        _test_today: current_date
      })
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    # Should fall back to formal name
    assert html =~ "Pfingstferien"
  end

  test "respects display_priority when rendering overlapping periods" do
    # Define overlapping periods - Pfingstferien with public holiday Fronleichnam inside
    periods = [
      # Pfingstferien (vacation) with lower priority
      %{
        starts_on: ~D[2025-06-10],
        ends_on: ~D[2025-06-20],
        holiday_or_vacation_type: %{name: "Pfingstferien", colloquial: "Pfingstferien"},
        is_school_vacation: true,
        # Lower priority
        display_priority: 1
      },
      # Fronleichnam (public holiday) with higher priority
      %{
        starts_on: ~D[2025-06-19],
        ends_on: ~D[2025-06-19],
        holiday_or_vacation_type: %{name: "Fronleichnam", colloquial: "Fronleichnam"},
        is_public_holiday: true,
        # Higher priority
        display_priority: 2
      }
    ]

    # Create days covering both periods
    days_to_show = create_days(~D[2025-06-01], 30)
    months = get_test_months()

    # Directly create and test the HTML output
    component = %{
      days_to_show: days_to_show,
      months: months,
      all_periods: periods,
      days_count: 30,
      months_with_days: [
        {"Juni", 30, 2025, 6}
      ]
    }

    # We need to extract the rendered HTML to check the cell colors
    html =
      VacationTimelineComponent.render(component)
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    # NOTE: The counts include the color markers in the legend at the bottom
    # We're not counting calendar emojis because they've replaced the green rectangles

    # Count green cells (vacation days) in the timeline only
    # Should be 10 days of Pfingstferien excluding Fronleichnam
    # Plus 1 for the legend marker = 11
    green_cell_count =
      html
      |> String.split("bg-green-600")
      |> length()
      # Subtract 1 because split results in one more segment than delimiters
      |> Kernel.-(1)

    # Count blue cells (public holidays) in the timeline
    # Should be 1 for Fronleichnam plus 1 for the legend marker = 2
    blue_cell_count =
      html
      |> String.split("bg-blue-600")
      |> length()
      |> Kernel.-(1)

    # Removed calendar emoji assertion as it's no longer used

    # Adjusted assertions accounting for the removed green rectangles in the status messages
    # 10 days of vacation + legend marker (no green rectangle in status anymore)
    assert green_cell_count == 11
    # 1 day of public holiday + legend marker
    assert blue_cell_count == 2

    # Verify that there is one date with both Pfingstferien and Fronleichnam mentioned
    assert html =~ "Pfingstferien"
    assert html =~ "Fronleichnam"
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
