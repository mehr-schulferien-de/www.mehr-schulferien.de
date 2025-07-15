defmodule MehrSchulferienWeb.FederalState.MonthEventsComponentTest do
  use MehrSchulferienWeb.ConnCase

  import Phoenix.LiveViewTest
  alias MehrSchulferienWeb.FederalState.MonthEventsComponent

  describe "month_events/1" do
    test "renders basic structure with public holidays and school periods" do
      public_period = %{
        starts_on: ~D[2026-05-01],
        ends_on: ~D[2026-05-01],
        holiday_or_vacation_type: %{
          name: "Tag der Arbeit",
          colloquial: nil
        }
      }

      school_period = %{
        starts_on: ~D[2026-05-15],
        ends_on: ~D[2026-05-15],
        holiday_or_vacation_type: %{
          name: "Beweglicher Ferientag",
          colloquial: nil
        },
        memo: nil
      }

      html =
        render_component(&MonthEventsComponent.month_events/1,
          month_public_periods: [public_period],
          month_periods: [school_period],
          all_periods: []
        )

      assert html =~ "Tag der Arbeit"
      assert html =~ "01.05."
      assert html =~ "Beweglicher Ferientag"
      assert html =~ "15.05."
      # Check that it contains the duration info (may include effective duration)
      assert html =~ "Tag)"
    end

    test "displays memo for Beweglicher Ferientag when present" do
      period_with_memo = %{
        starts_on: ~D[2026-05-15],
        ends_on: ~D[2026-05-15],
        holiday_or_vacation_type: %{
          name: "Beweglicher Ferientag",
          colloquial: nil
        },
        memo: "Freitag nach Christi Himmelfahrt"
      }

      html =
        render_component(&MonthEventsComponent.month_events/1,
          month_public_periods: [],
          month_periods: [period_with_memo],
          all_periods: []
        )

      assert html =~ "Beweglicher Ferientag"
      assert html =~ "Freitag nach Christi Himmelfahrt"
      assert html =~ "text-xs text-gray-600"
    end

    test "does not display memo for other vacation types" do
      regular_vacation = %{
        starts_on: ~D[2026-07-01],
        ends_on: ~D[2026-08-15],
        holiday_or_vacation_type: %{
          name: "Sommerferien",
          colloquial: nil
        },
        memo: "Should not be displayed"
      }

      html =
        render_component(&MonthEventsComponent.month_events/1,
          month_public_periods: [],
          month_periods: [regular_vacation],
          all_periods: []
        )

      assert html =~ "Sommerferien"
      refute html =~ "Should not be displayed"
    end

    test "does not display memo section when memo is empty string" do
      period_empty_memo = %{
        starts_on: ~D[2026-05-15],
        ends_on: ~D[2026-05-15],
        holiday_or_vacation_type: %{
          name: "Beweglicher Ferientag",
          colloquial: nil
        },
        memo: ""
      }

      html =
        render_component(&MonthEventsComponent.month_events/1,
          month_public_periods: [],
          month_periods: [period_empty_memo],
          all_periods: []
        )

      assert html =~ "Beweglicher Ferientag"
      refute html =~ "text-xs text-gray-600 block"
    end

    test "handles nil memo gracefully" do
      period_nil_memo = %{
        starts_on: ~D[2026-05-15],
        ends_on: ~D[2026-05-15],
        holiday_or_vacation_type: %{
          name: "Beweglicher Ferientag",
          colloquial: nil
        },
        memo: nil
      }

      html =
        render_component(&MonthEventsComponent.month_events/1,
          month_public_periods: [],
          month_periods: [period_nil_memo],
          all_periods: []
        )

      assert html =~ "Beweglicher Ferientag"
      refute html =~ "text-xs text-gray-600 block"
    end

    test "displays multiple Beweglicher Ferientage with different memo states" do
      periods = [
        %{
          starts_on: ~D[2026-03-18],
          ends_on: ~D[2026-03-18],
          holiday_or_vacation_type: %{
            name: "Beweglicher Ferientag",
            colloquial: nil
          },
          memo: "Vor den Osterferien"
        },
        %{
          starts_on: ~D[2026-03-19],
          ends_on: ~D[2026-03-19],
          holiday_or_vacation_type: %{
            name: "Beweglicher Ferientag",
            colloquial: nil
          },
          memo: nil
        },
        %{
          starts_on: ~D[2026-05-15],
          ends_on: ~D[2026-05-15],
          holiday_or_vacation_type: %{
            name: "Beweglicher Ferientag",
            colloquial: nil
          },
          memo: "Freitag nach Christi Himmelfahrt"
        }
      ]

      html =
        render_component(&MonthEventsComponent.month_events/1,
          month_public_periods: [],
          month_periods: periods,
          all_periods: []
        )

      # Should show memo for first period
      assert html =~ "Vor den Osterferien"

      # Should show memo for third period
      assert html =~ "Freitag nach Christi Himmelfahrt"

      # All periods should be displayed
      # 3 occurrences + 1
      assert Enum.count(String.split(html, "Beweglicher Ferientag")) == 4
    end

    test "formats date ranges correctly for multi-day periods" do
      multi_day_period = %{
        starts_on: ~D[2026-03-30],
        ends_on: ~D[2026-04-10],
        holiday_or_vacation_type: %{
          name: "Osterferien",
          colloquial: nil
        },
        memo: nil
      }

      html =
        render_component(&MonthEventsComponent.month_events/1,
          month_public_periods: [],
          month_periods: [multi_day_period],
          all_periods: []
        )

      assert html =~ "30.03. - 10.04."
      # Check that it shows the base duration (12 days)
      assert html =~ "(12"
      assert html =~ "Tage)"
    end

    test "shows effective duration with difference when applicable" do
      period = %{
        starts_on: ~D[2026-03-30],
        ends_on: ~D[2026-04-10],
        holiday_or_vacation_type: %{
          name: "Osterferien",
          colloquial: nil
        },
        memo: nil
      }

      # Mock all_periods to simulate adjoining weekends/holidays
      all_periods = [
        period,
        %{starts_on: ~D[2026-04-11], ends_on: ~D[2026-04-12], is_public_holiday: true}
      ]

      html =
        render_component(&MonthEventsComponent.month_events/1,
          month_public_periods: [],
          month_periods: [period],
          all_periods: all_periods
        )

      assert html =~ "Osterferien"
      # The component should show the duration calculation
      assert html =~ "Tage)"
    end

    test "uses colloquial name when available" do
      period = %{
        starts_on: ~D[2026-12-22],
        ends_on: ~D[2027-01-07],
        holiday_or_vacation_type: %{
          name: "Weihnachtsferien",
          colloquial: "Winterferien"
        },
        memo: nil
      }

      html =
        render_component(&MonthEventsComponent.month_events/1,
          month_public_periods: [],
          month_periods: [period],
          all_periods: []
        )

      assert html =~ "Winterferien"
      refute html =~ "Weihnachtsferien"
    end
  end
end
