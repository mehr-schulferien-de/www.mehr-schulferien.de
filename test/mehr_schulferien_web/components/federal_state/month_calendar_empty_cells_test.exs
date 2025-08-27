defmodule MehrSchulferienWeb.FederalState.MonthCalendarEmptyCellsTest do
  use MehrSchulferienWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias MehrSchulferienWeb.FederalState.MonthCalendarComponent

  describe "month_calendar/1 empty cells rendering" do
    test "September 2025 - should not render cells for days after 30th" do
      # September 2025: 30 days, starts on Monday (weekday 1)
      # Last row should have days 29, 30, then 5 empty cells without borders

      html =
        render_component(&MonthCalendarComponent.month_calendar/1,
          month: 9,
          year: 2025,
          periods: [],
          public_periods: [],
          all_periods: []
        )

      # Count cells with day numbers (1-30)
      cells_with_days = Regex.scan(~r/<td[^>]*>\s*(\d+)\.\s*<\/td>/, html)
      assert length(cells_with_days) == 30

      # Check that we have cells for days 29 and 30
      day_numbers = cells_with_days |> Enum.map(fn [_, day] -> String.to_integer(day) end)
      assert 29 in day_numbers
      assert 30 in day_numbers

      # Check for empty cell with colspan at the end (accounting for whitespace in formatted HTML)
      empty_cell_with_colspan =
        Regex.scan(
          ~r/<td\s+colspan="5"\s+class="border border-gray-200 dark:border-gray-700"\s*>\s*<\/td>/,
          html
        )

      assert length(empty_cell_with_colspan) == 1,
             "Should have exactly 1 empty cell with colspan=5 at the end of September 2025"
    end

    test "February 2024 (leap year) - should render correctly with 29 days" do
      # February 2024: 29 days (leap year), starts on Thursday (weekday 4)
      # First row: 3 empty cells, then days 1-4 (total 7 cells)
      # Last row: days 26-29, then 3 empty cells

      html =
        render_component(&MonthCalendarComponent.month_calendar/1,
          month: 2,
          year: 2024,
          periods: [],
          public_periods: [],
          all_periods: []
        )

      # Count cells with day numbers
      cells_with_days = Regex.scan(~r/<td[^>]*>\s*(\d+)\.\s*<\/td>/, html)
      assert length(cells_with_days) == 29, "February 2024 should have exactly 29 days"

      # Check for empty cells with colspan (accounting for whitespace in formatted HTML)
      empty_cells_start =
        Regex.scan(
          ~r/<td\s+colspan="3"\s+class="border border-gray-200 dark:border-gray-700"\s*>\s*<\/td>/,
          html
        )

      assert length(empty_cells_start) == 2,
             "February 2024 should have 2 cells with colspan=3 (one at start, one at end)"
    end

    test "November 2025 - month ending on Sunday should have no empty cells in last row" do
      # November 2025: 30 days, starts on Saturday (weekday 6)
      # First row: 5 empty cells, then days 1-2
      # Last row should be full: days 24-30 (no empty cells needed)

      html =
        render_component(&MonthCalendarComponent.month_calendar/1,
          month: 11,
          year: 2025,
          periods: [],
          public_periods: [],
          all_periods: []
        )

      # Count cells with day numbers
      cells_with_days = Regex.scan(~r/<td[^>]*>\s*(\d+)\.\s*<\/td>/, html)
      assert length(cells_with_days) == 30

      # Check for empty cell with colspan at the beginning (accounting for whitespace in formatted HTML)
      empty_cell_with_colspan =
        Regex.scan(
          ~r/<td\s+colspan="5"\s+class="border border-gray-200 dark:border-gray-700"\s*>\s*<\/td>/,
          html
        )

      assert length(empty_cell_with_colspan) == 1,
             "November 2025 should have exactly 1 empty cell with colspan=5 at the beginning"

      # Verify last day is 30
      day_numbers = cells_with_days |> Enum.map(fn [_, day] -> String.to_integer(day) end)
      assert Enum.max(day_numbers) == 30
    end
  end
end
