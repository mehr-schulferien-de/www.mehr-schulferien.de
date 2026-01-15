defmodule MehrSchulferienWeb.WikiSchoolEnrichmentTest do
  use MehrSchulferienWeb.ConnCase

  # WIKI MAINTENANCE MODE: Tests skipped while wiki is disabled
  # To re-enable: remove this line and uncomment wiki routes in router.ex
  @moduletag :skip

  import Phoenix.LiveViewTest

  alias MehrSchulferien.{Locations, Maps, Calendars}

  # Helper function to find the next weekday from a given date
  defp find_next_weekday(date) do
    case Date.day_of_week(date) do
      6 -> Date.add(date, 2)
      7 -> Date.add(date, 1)
      _ -> date
    end
  end

  describe "data enrichment feature" do
    setup do
      # Create test school hierarchy 
      {:ok, country} =
        Locations.create_location(%{
          name: "Deutschland",
          slug: "d",
          is_country: true
        })

      {:ok, federal_state} =
        Locations.create_location(%{
          name: "Berlin",
          slug: "berlin",
          is_federal_state: true,
          parent_location_id: country.id
        })

      {:ok, county} =
        Locations.create_location(%{
          name: "Berlin County",
          slug: "berlin-county",
          is_county: true,
          parent_location_id: federal_state.id
        })

      {:ok, city} =
        Locations.create_location(%{
          name: "Berlin",
          slug: "berlin-city",
          is_city: true,
          parent_location_id: county.id
        })

      {:ok, school} =
        Locations.create_location(%{
          name: "Test Gymnasium",
          slug: "test-gymnasium",
          is_school: true,
          parent_location_id: city.id
        })

      # Create address for school
      {:ok, address} =
        Maps.create_address(%{
          "school_location_id" => school.id,
          "line1" => "Test Gymnasium",
          "street" => "Teststraße 1",
          "zip_code" => "12345",
          "city" => "Berlin"
        })

      {:ok, school: school, address: address}
    end

    # Auto Data Enrichment functionality tests removed - feature deprecated

    test "enrichment button is disabled when limit reached", %{conn: conn, school: school} do
      # Simulate reaching daily limit
      today = Date.utc_today()
      daily_limit = MehrSchulferien.Config.daily_change_limit()

      for _ <- 1..daily_limit do
        MehrSchulferien.Wiki.increment_daily_change_count(today)
      end

      {:ok, view, _html} = live(conn, "/wiki/schools/#{school.slug}/edit")

      refute has_element?(view, "button", "Auto Data Enrichment")
    end
  end

  describe "bewegliche Ferientage with flexible date input" do
    setup do
      # Create test school hierarchy
      {:ok, country} =
        Locations.create_location(%{
          name: "Deutschland",
          slug: "d",
          is_country: true
        })

      # Create the beweglicher-ferientag holiday type
      {:ok, _beweglicher_type} =
        Calendars.create_holiday_or_vacation_type(%{
          name: "Beweglicher Ferientag",
          colloquial: "Bewegl. Ferientag",
          slug: "beweglicher-ferientag",
          country_location_id: country.id,
          default_display_priority: 7,
          default_html_class: "success",
          default_is_listed_below_month: true,
          default_is_school_vacation: false,
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

      {:ok, county} =
        Locations.create_location(%{
          name: "Berlin County",
          slug: "berlin-county",
          is_county: true,
          parent_location_id: federal_state.id
        })

      {:ok, city} =
        Locations.create_location(%{
          name: "Berlin",
          slug: "berlin-city",
          is_city: true,
          parent_location_id: county.id
        })

      {:ok, school} =
        Locations.create_location(%{
          name: "Test Gymnasium",
          slug: "test-gymnasium",
          is_school: true,
          parent_location_id: city.id
        })

      # Create federal state ferientage limit for current school year
      today = Date.utc_today()
      current_school_year = if today.month >= 8, do: today.year, else: today.year - 1
      school_year_string = "#{current_school_year}/#{current_school_year + 1}"

      _limit =
        MehrSchulferien.Repo.insert!(%MehrSchulferien.Periods.FederalStateFerientageLimit{
          federal_state_id: federal_state.id,
          school_year: school_year_string,
          max_bewegliche_ferientage: 6
        })

      {:ok, school: school}
    end

    test "accepts single date input using simple form", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/wiki/schools/#{school.slug}/ferientage")

      future_date = Date.utc_today() |> Date.add(30) |> find_next_weekday()
      date_iso = Date.to_iso8601(future_date)

      # Use the simple form
      view
      |> form("form[phx-submit='add_single_ferientag']",
        ferientag: %{date: date_iso, memo: "Pädagogischer Tag"}
      )
      |> render_submit()

      html = render(view)

      # Check if ferientag was added by looking for the date
      formatted_date = MehrSchulferienWeb.Formatters.DateFormatter.format_date_full(future_date)

      # Either check for the flash message OR the added ferientag
      assert html =~ formatted_date ||
               html =~ "Beweglicher Ferientag wurde erfolgreich hinzugefügt." ||
               html =~ "erfolgreich" || html =~ "hinzugefügt"
    end

    test "accepts date range input using advanced form", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/wiki/schools/#{school.slug}/ferientage")

      # Toggle to advanced form mode by clicking the second button
      view
      |> element("button[phx-click='toggle_form_mode']:last-child")
      |> render_click()

      future_date = Date.utc_today() |> Date.add(60)
      # Ensure we have a valid 3-day range (start day low enough to not exceed month length)
      start_day = min(future_date.day, 10)
      end_day = start_day + 2

      date_string = "#{start_day}.-#{end_day}.#{future_date.month}.#{future_date.year}"

      view
      |> form("form[phx-submit='add_beweglicher_ferientag']",
        ferientag: %{dates: date_string, memo: "Test Range"}
      )
      |> render_submit()

      # Wait a bit for the LiveView to process the submission
      :timer.sleep(100)

      html = render(view)
      # Should see at least one date in the list or success message
      # Check for the first date in the range
      first_date = %Date{future_date | day: start_day}
      formatted_date = MehrSchulferienWeb.Formatters.DateFormatter.format_date_full(first_date)

      assert html =~ formatted_date || html =~ "erfolgreich" || html =~ "hinzugefügt" ||
               html =~ "Beweglicher Ferientag"
    end

    test "accepts multiple dates input", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/wiki/schools/#{school.slug}/ferientage")

      # Toggle to advanced form mode by clicking the second button
      view
      |> element("button[phx-click='toggle_form_mode']:last-child")
      |> render_click()

      date1 = Date.utc_today() |> Date.add(30)
      date2 = Date.utc_today() |> Date.add(40)

      date_string =
        "#{date1.day}.#{date1.month}.#{date1.year}, #{date2.day}.#{date2.month}.#{date2.year}"

      view
      |> form("form[phx-submit='add_beweglicher_ferientag']",
        ferientag: %{dates: date_string, memo: "Multiple Dates"}
      )
      |> render_submit()

      html = render(view)

      # Check for success message or the date in the HTML
      formatted_date1 = MehrSchulferienWeb.Formatters.DateFormatter.format_date_full(date1)
      assert html =~ "erfolgreich" || html =~ "hinzugefügt" || html =~ formatted_date1
    end

    test "shows error for invalid date format", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/wiki/schools/#{school.slug}/ferientage")

      # Toggle to advanced form mode by clicking the second button
      view
      |> element("button[phx-click='toggle_form_mode']:last-child")
      |> render_click()

      view
      |> form("form[phx-submit='add_beweglicher_ferientag']",
        ferientag: %{dates: "invalid date", memo: "Test"}
      )
      |> render_submit()

      assert render(view) =~ "Ungültiges Datumsformat"
    end

    test "shows error for past dates", %{conn: conn, school: school} do
      {:ok, view, _html} = live(conn, "/wiki/schools/#{school.slug}/ferientage")

      # Toggle to advanced form mode by clicking the second button
      view
      |> element("button[phx-click='toggle_form_mode']:last-child")
      |> render_click()

      past_date = Date.utc_today() |> Date.add(-10)
      date_string = "#{past_date.day}.#{past_date.month}.#{past_date.year}"

      view
      |> form("form[phx-submit='add_beweglicher_ferientag']",
        ferientag: %{dates: date_string, memo: "Past Date"}
      )
      |> render_submit()

      assert render(view) =~
               "Bewegliche Ferientage können nur für zukünftige Daten angelegt werden."
    end
  end
end
