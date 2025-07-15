defmodule MehrSchulferienWeb.School.PeriodsTableComponentTest do
  use MehrSchulferienWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias MehrSchulferienWeb.School.PeriodsTableComponent

  describe "periods_table component" do
    test "renders periods table with school year grouping" do
      # Create test periods
      periods = [
        build_period(~D[2024-09-01], ~D[2024-09-15], "Herbstferien"),
        build_period(~D[2024-12-23], ~D[2025-01-06], "Weihnachtsferien"),
        build_period(~D[2025-02-10], ~D[2025-02-14], "Winterferien")
      ]

      assigns = %{
        periods: periods,
        all_periods: periods,
        today: ~D[2024-10-15]
      }

      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      # Check school year headers
      assert html =~ "Schuljahr 2024/2025"

      # Check period names
      assert html =~ "Herbstferien"
      assert html =~ "Weihnachtsferien"
      assert html =~ "Winterferien"

      # Check table structure
      assert html =~ "<table"
      assert html =~ "<thead>"
      assert html =~ "<tbody class=\"divide-y divide-gray-200\">"
      assert html =~ "Name"
      assert html =~ "Termin"
      assert html =~ "Tage*"
    end

    test "displays memo for Beweglicher Ferientag with memo" do
      # Create a Beweglicher Ferientag with memo
      period_with_memo = %{
        starts_on: ~D[2024-05-10],
        ends_on: ~D[2024-05-10],
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
        today: ~D[2024-04-01]
      }

      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      # Check that the memo is displayed
      assert html =~ "Beweglicher Ferientag"
      assert html =~ "Tag nach Christi Himmelfahrt"
      assert html =~ "text-xs text-gray-600 mt-1"
    end

    test "does not display memo for non-Beweglicher Ferientag periods" do
      # Create a regular vacation period with memo
      regular_period = %{
        starts_on: ~D[2024-07-15],
        ends_on: ~D[2024-08-27],
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
        today: ~D[2024-06-01]
      }

      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      # Check that regular vacation is displayed but memo is not
      assert html =~ "Sommerferien"
      refute html =~ "This memo should not be displayed"
    end

    test "does not display memo section for Beweglicher Ferientag with empty memo" do
      # Create a Beweglicher Ferientag with empty memo
      period_empty_memo = %{
        starts_on: ~D[2024-05-31],
        ends_on: ~D[2024-05-31],
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
        today: ~D[2024-05-01]
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
        starts_on: ~D[2024-06-03],
        ends_on: ~D[2024-06-03],
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
        today: ~D[2024-05-01]
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
          starts_on: ~D[2024-05-10],
          ends_on: ~D[2024-05-10],
          holiday_or_vacation_type: %{
            name: "Beweglicher Ferientag",
            colloquial: "Beweglicher Ferientag"
          },
          memo: "Tag nach Christi Himmelfahrt"
        },
        %{
          starts_on: ~D[2024-05-31],
          ends_on: ~D[2024-05-31],
          holiday_or_vacation_type: %{
            name: "Beweglicher Ferientag",
            colloquial: "Beweglicher Ferientag"
          },
          memo: ""
        },
        %{
          starts_on: ~D[2024-06-21],
          ends_on: ~D[2024-06-21],
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
        today: ~D[2024-04-01]
      }

      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      # Check that memos are displayed correctly
      assert html =~ "Tag nach Christi Himmelfahrt"
      assert html =~ "Vor den Sommerferien"

      # Count occurrences of the memo div styling
      memo_div_count =
        html
        |> String.split("text-xs text-gray-600 mt-1")
        |> length()
        |> Kernel.-(1)

      # Should have exactly 2 memo divs (for the two non-empty memos)
      assert memo_div_count == 2
    end

    test "highlights current period correctly" do
      periods = [
        build_period(~D[2024-09-01], ~D[2024-09-15], "Herbstferien"),
        build_period(~D[2024-10-14], ~D[2024-10-25], "Herbstferien"),
        build_period(~D[2024-12-23], ~D[2025-01-06], "Weihnachtsferien")
      ]

      assigns = %{
        periods: periods,
        all_periods: periods,
        # During second period
        today: ~D[2024-10-15]
      }

      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      # Check for highlighting class
      assert html =~ "bg-yellow-100"

      # Check that past periods have gray text
      assert html =~ "text-gray-400"
    end

    test "calculates effective duration correctly" do
      # Create periods where one includes weekends
      periods = [
        %{
          # Monday
          starts_on: ~D[2024-10-21],
          # Friday
          ends_on: ~D[2024-10-25],
          holiday_or_vacation_type: %{
            name: "Herbstferien",
            colloquial: "Herbstferien"
          }
        }
      ]

      assigns = %{
        periods: periods,
        all_periods: periods,
        today: ~D[2024-10-01]
      }

      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      # Should show the footnote about effective duration
      assert html =~
               "* Die effektive Dauer in Tagen enthält an die Ferien angrenzende Wochenenden und Feiertage."
    end

    test "generates correct anchor links for calendar navigation" do
      periods = [
        build_period(~D[2024-07-15], ~D[2024-08-27], "Sommerferien"),
        build_period(~D[2024-10-28], ~D[2024-11-01], "Herbstferien")
      ]

      assigns = %{
        periods: periods,
        all_periods: periods,
        today: ~D[2024-06-01]
      }

      html = render_component(&PeriodsTableComponent.periods_table/1, assigns)

      # Check for correct anchor links - using escaped quotes in HTML
      assert html =~ "onclick=\"window.location.href=&#39;#juli2024&#39;\""
      assert html =~ "onclick=\"window.location.href=&#39;#oktober2024&#39;\""
    end
  end

  # Helper function to build a period
  defp build_period(starts_on, ends_on, type_name) do
    %{
      starts_on: starts_on,
      ends_on: ends_on,
      holiday_or_vacation_type: %{
        name: type_name,
        colloquial: type_name
      }
    }
  end
end
