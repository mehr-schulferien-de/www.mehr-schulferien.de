defmodule MehrSchulferienWeb.School.PeriodsTableComponentTest do
  use MehrSchulferienWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias MehrSchulferienWeb.School.PeriodsTableComponent

  describe "periods_table component" do
    test "renders periods table with school year grouping" do
      # Create test periods
      periods = [
        build_period(~D[2024-09-30], ~D[2024-10-11], "Herbstferien"),
        build_period(~D[2025-01-07], ~D[2025-01-17], "Weihnachtsferien"),
        build_period(~D[2025-04-14], ~D[2025-04-26], "Osterferien"),
        build_period(~D[2025-10-13], ~D[2025-10-24], "Winterferien")
      ]

      assigns = %{
        periods: periods,
        all_periods: periods,
        today: ~D[2025-03-15],
        current_school_year: 2024,
        next_school_year: 2025
      }

      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      # Check school year headers
      assert html =~ "Schuljahr 2024/2025"
      assert html =~ "Schuljahr 2025/2026"

      # Finished dates stay in the markup but move into the collapsed block
      assert html =~ "2 vergangene Termine anzeigen"
      assert html =~ "Herbstferien"
      assert html =~ "Weihnachtsferien"
      # Still ahead of today
      assert html =~ "Osterferien"
      assert html =~ "Winterferien"

      # The running school year still has dates ahead of it
      assert html =~ "Aktuell"
      assert html =~ "Kommend"

      # Check table structure
      assert html =~ "<table"
      assert html =~ "<thead>"
      assert html =~ "<tbody class=\"divide-y divide-gray-200 dark:divide-gray-700\">"
      assert html =~ "Name"
      assert html =~ "Termin"
      assert html =~ "Tage"
    end

    test "displays memo for Beweglicher Ferientag with memo" do
      # Create a Beweglicher Ferientag with memo
      period_with_memo = %{
        starts_on: ~D[2025-05-10],
        ends_on: ~D[2025-05-10],
        holiday_or_vacation_type: %{
          name: "Beweglicher Ferientag",
          colloquial: "Beweglicher Ferientag"
        },
        memo: "Tag nach Christi Himmelfahrt"
      }

      periods = [period_with_memo]

      assigns = %{
        periods: periods,
        all_periods: periods,
        today: ~D[2024-09-01],
        current_school_year: 2024,
        next_school_year: 2025
      }

      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      # Check that the memo is displayed
      assert html =~ "Beweglicher Ferientag"
      assert html =~ "Tag nach Christi Himmelfahrt"
      assert html =~ "text-xs text-gray-600 dark:text-gray-400 mt-1"
    end

    test "does not display memo for non-Beweglicher Ferientag periods" do
      # Create a regular vacation period with memo
      regular_period = %{
        starts_on: ~D[2025-07-15],
        ends_on: ~D[2025-08-27],
        holiday_or_vacation_type: %{
          name: "Sommerferien",
          colloquial: "Sommerferien"
        },
        memo: "This memo should not be displayed"
      }

      periods = [regular_period]

      assigns = %{
        periods: periods,
        all_periods: periods,
        today: ~D[2024-09-01],
        current_school_year: 2024,
        next_school_year: 2025
      }

      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      # Check that regular vacation is displayed but memo is not
      assert html =~ "Sommerferien"
      refute html =~ "This memo should not be displayed"
    end

    test "does not display memo section for Beweglicher Ferientag with empty memo" do
      # Create a Beweglicher Ferientag with empty memo
      period_empty_memo = %{
        starts_on: ~D[2025-05-31],
        ends_on: ~D[2025-05-31],
        holiday_or_vacation_type: %{
          name: "Beweglicher Ferientag",
          colloquial: "Beweglicher Ferientag"
        },
        memo: ""
      }

      periods = [period_empty_memo]

      assigns = %{
        periods: periods,
        all_periods: periods,
        today: ~D[2024-09-01],
        current_school_year: 2024,
        next_school_year: 2025
      }

      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      # Check that Beweglicher Ferientag is displayed but no memo div
      assert html =~ "Beweglicher Ferientag"
      # Should not have the memo styling div
      refute html =~ "text-xs text-gray-600 mt-1"
    end

    test "does not display memo section for Beweglicher Ferientag with nil memo" do
      # Create a Beweglicher Ferientag without memo field
      period_nil_memo = %{
        starts_on: ~D[2024-11-03],
        ends_on: ~D[2024-11-03],
        holiday_or_vacation_type: %{
          name: "Beweglicher Ferientag",
          colloquial: "Beweglicher Ferientag"
        },
        memo: nil
      }

      periods = [period_nil_memo]

      assigns = %{
        periods: periods,
        all_periods: periods,
        today: ~D[2024-09-01],
        current_school_year: 2024,
        next_school_year: 2025
      }

      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      # Check that Beweglicher Ferientag is displayed but no memo div
      assert html =~ "Beweglicher Ferientag"
      # Should not have the memo styling div
      refute html =~ "text-xs text-gray-600 mt-1"
    end

    test "handles multiple Beweglicher Ferientage with different memo states" do
      periods = [
        %{
          starts_on: ~D[2025-05-10],
          ends_on: ~D[2025-05-10],
          holiday_or_vacation_type: %{
            name: "Beweglicher Ferientag",
            colloquial: "Beweglicher Ferientag"
          },
          memo: "Tag nach Christi Himmelfahrt"
        },
        %{
          starts_on: ~D[2025-05-31],
          ends_on: ~D[2025-05-31],
          holiday_or_vacation_type: %{
            name: "Beweglicher Ferientag",
            colloquial: "Beweglicher Ferientag"
          },
          memo: ""
        },
        %{
          starts_on: ~D[2025-06-21],
          ends_on: ~D[2025-06-21],
          holiday_or_vacation_type: %{
            name: "Beweglicher Ferientag",
            colloquial: "Beweglicher Ferientag"
          },
          memo: "Vor den Sommerferien"
        }
      ]

      assigns = %{
        periods: periods,
        all_periods: periods,
        today: ~D[2024-09-01],
        current_school_year: 2024,
        next_school_year: 2025
      }

      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      # Check that memos are displayed correctly
      assert html =~ "Tag nach Christi Himmelfahrt"
      assert html =~ "Vor den Sommerferien"

      # Count occurrences of the memo div styling
      memo_div_count =
        html
        |> String.split("text-xs text-gray-600 dark:text-gray-400 mt-1")
        |> length()
        |> Kernel.-(1)

      # Should have exactly 2 memo divs (for the two non-empty memos)
      assert memo_div_count == 2
    end

    test "highlights current period correctly" do
      periods = [
        build_period(~D[2024-09-01], ~D[2024-09-15], "Herbstferien"),
        build_period(~D[2025-10-14], ~D[2025-10-25], "Herbstferien"),
        build_period(~D[2025-12-23], ~D[2026-01-06], "Weihnachtsferien")
      ]

      assigns = %{
        periods: periods,
        all_periods: periods,
        # During second period
        today: ~D[2025-10-15],
        current_school_year: 2025,
        next_school_year: 2026
      }

      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      # Check for highlighting class for current period
      assert html =~ "bg-yellow-100"

      # Nothing in the two rendered school years has finished yet, so there is
      # no collapsed block. The 2024/2025 period belongs to neither.
      refute html =~ "vergangene"
    end

    test "calculates effective duration correctly" do
      # Create periods where one includes weekends
      periods = [
        %{
          # Monday
          starts_on: ~D[2025-10-21],
          # Friday
          ends_on: ~D[2025-10-25],
          holiday_or_vacation_type: %{
            name: "Herbstferien",
            colloquial: "Herbstferien"
          }
        }
      ]

      assigns = %{
        periods: periods,
        all_periods: periods,
        today: ~D[2025-10-01],
        current_school_year: 2025,
        next_school_year: 2026
      }

      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      # Should show the footnote about effective duration
      assert html =~
               "Die Anzahl der Tage enthält angrenzende Wochenenden und Feiertage."
    end

    test "generates correct anchor links for calendar navigation" do
      periods = [
        build_period(~D[2025-08-04], ~D[2025-08-15], "Sommerferien"),
        build_period(~D[2025-10-28], ~D[2025-11-01], "Herbstferien")
      ]

      assigns = %{
        periods: periods,
        all_periods: periods,
        today: ~D[2025-09-01],
        current_school_year: 2025,
        next_school_year: 2026
      }

      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      # Check for correct anchor links - using escaped quotes in HTML
      assert html =~ "onclick=\"window.location.href=&#39;#oktober2025&#39;\""

      # The August Sommerferien are over, so their row does not offer an anchor
      # into a month the calendar view no longer renders
      assert html =~ "Sommerferien"
      refute html =~ "#august2025"
    end
  end

  describe "during the Sommerferien" do
    # The school year nominally runs until 31 July, so in late July the table
    # used to lead with months of dates that were long over.
    setup do
      old_year = [
        build_period(~D[2025-10-13], ~D[2025-10-24], "Herbstferien"),
        build_period(~D[2026-03-18], ~D[2026-03-19], "Beweglicher Ferientag"),
        build_period(~D[2026-03-30], ~D[2026-04-10], "Osterferien"),
        build_period(~D[2026-06-29], ~D[2026-08-07], "Sommerferien")
      ]

      new_year = [
        build_period(~D[2026-10-12], ~D[2026-10-23], "Herbstferien 2026"),
        build_period(~D[2026-12-21], ~D[2027-01-08], "Weihnachtsferien 2026")
      ]

      assigns = %{
        periods: old_year ++ new_year,
        all_periods: old_year ++ new_year,
        today: ~D[2026-07-25],
        current_school_year: 2025,
        next_school_year: 2026
      }

      {:ok, assigns: assigns}
    end

    test "collapses the finished dates of the old school year", %{assigns: assigns} do
      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      assert html =~ "<details"
      assert html =~ "3 vergangene Termine anzeigen"

      # The finished dates stay in the markup for long-tail search traffic
      assert html =~ "Herbstferien"
      assert html =~ "Osterferien"
    end

    test "shows the running Sommerferien outside the collapsed block", %{assigns: assigns} do
      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      [_before_details, after_details] = String.split(html, "</details>", parts: 2)

      assert after_details =~ "Sommerferien"
      # Running periods keep their highlight
      assert html =~ "bg-yellow-100"
    end

    test "labels the old school year as running out, not as current", %{assigns: assigns} do
      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      assert html =~ "Läuft noch"
      refute html =~ "Aktuell"
      assert html =~ "Kommend"
    end

    test "keeps the new school year fully visible", %{assigns: assigns} do
      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      assert html =~ "Schuljahr 2026/2027"
      assert html =~ "Herbstferien 2026"
      assert html =~ "Weihnachtsferien 2026"
    end

    test "marks a school year whose dates are all over as finished", %{assigns: assigns} do
      # A state whose Sommerferien ended before 1 August
      periods =
        Enum.map(assigns.periods, fn
          %{holiday_or_vacation_type: %{name: "Sommerferien"}} = period ->
            %{period | starts_on: ~D[2026-06-15], ends_on: ~D[2026-07-24]}

          period ->
            period
        end)

      assigns = %{assigns | periods: periods, all_periods: periods}

      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      assert html =~ "Beendet"
      assert html =~ "4 vergangene Termine anzeigen"
      refute html =~ "Läuft noch"
    end
  end

  # Helper function to build a period
  defp build_period(starts_on, ends_on, type_name) do
    %{
      starts_on: starts_on,
      ends_on: ends_on,
      memo: nil,
      holiday_or_vacation_type: %{
        name: type_name,
        colloquial: type_name
      }
    }
  end
end
