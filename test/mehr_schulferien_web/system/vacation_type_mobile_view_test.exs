defmodule MehrSchulferienWeb.System.VacationTypeMobileViewTest do
  use MehrSchulferienWeb.ConnCase, async: false

  alias MehrSchulferien.{Locations, Calendars, Periods}

  describe "vacation type page mobile view" do
    setup do
      # Create minimal test data
      {:ok, country} =
        Locations.create_location(%{
          name: "Deutschland",
          slug: "d",
          is_country: true
        })

      {:ok, herbst_type} =
        Calendars.create_holiday_or_vacation_type(%{
          name: "Herbstferien",
          colloquial: "Herbstferien",
          slug: "herbst",
          country_location_id: country.id,
          default_display_priority: 3,
          default_html_class: "green",
          default_is_listed_below_month: true,
          default_is_school_vacation: true,
          default_is_public_holiday: false,
          default_is_valid_for_students: true,
          default_is_valid_for_everybody: false
        })

      {:ok, federal_state} =
        Locations.create_location(%{
          name: "Berlin",
          slug: "berlin",
          is_federal_state: true,
          parent_location_id: country.id
        })

      {:ok, period} =
        Periods.create_period(%{
          starts_on: ~D[2025-10-20],
          ends_on: ~D[2025-11-01],
          location_id: federal_state.id,
          html_class: "green",
          is_listed_below_month: true,
          is_school_vacation: true,
          is_public_holiday: false,
          is_valid_for_students: true,
          is_valid_for_everybody: false,
          holiday_or_vacation_type_id: herbst_type.id,
          created_by_email_address: "test@example.com"
        })

      %{
        country: country,
        federal_state: federal_state,
        herbst_type: herbst_type,
        period: period
      }
    end

    test "displays end dates on mobile view using card layout", %{conn: conn} do
      # Visit herbstferien page
      conn = get(conn, ~p"/herbstferien")
      html = html_response(conn, 200)

      # Mobile view should have card layout (hidden on desktop)
      assert html =~ ~r/class="[^"]*md:hidden[^"]*"/

      # Mobile cards should display "Beginn:" and "Ende:" labels
      assert html =~ "Beginn:"
      assert html =~ "Ende:"

      # Desktop table should be hidden on mobile
      assert html =~ ~r/class="[^"]*hidden md:block[^"]*"/

      # Desktop table should have "Ende" column header
      assert html =~ "Ende"
    end

    test "mobile card layout displays all vacation information", %{conn: conn, period: period} do
      conn = get(conn, ~p"/herbstferien")
      html = html_response(conn, 200)

      # Check for mobile card structure
      assert html =~ ~r/class="[^"]*md:hidden[^"]*space-y-3[^"]*"/

      # Verify the date is displayed in cards
      # Format: DD.MM.YYYY
      start_date = Calendar.strftime(period.starts_on, "%d.%m.%Y")
      end_date = Calendar.strftime(period.ends_on, "%d.%m.%Y")

      assert html =~ start_date
      assert html =~ end_date

      # Verify Berlin is displayed in the cards
      assert html =~ "Berlin"
    end
  end
end
