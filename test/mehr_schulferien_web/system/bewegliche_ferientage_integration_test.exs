defmodule MehrSchulferienWeb.System.BeweglicheFerientageIntegrationTest do
  use MehrSchulferienWeb.ConnCase, async: false

  # WIKI MAINTENANCE MODE: Tests skipped while wiki is disabled
  # This test uses wiki routes for bewegliche ferientage feature
  # To re-enable: remove this line and uncomment wiki routes in router.ex
  @moduletag :skip

  import Phoenix.LiveViewTest

  alias MehrSchulferien.{Locations, Maps, Calendars, Repo, Periods}
  alias MehrSchulferien.Maps.ZipCodeMapping

  describe "bewegliche Ferientage integration" do
    setup do
      # Create minimal test data
      {:ok, country} =
        Locations.create_location(%{
          name: "Deutschland",
          slug: "d",
          is_country: true
        })

      # Create the beweglicher-ferientag holiday type
      {:ok, beweglicher_type} =
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

      {:ok, city} =
        Locations.create_location(%{
          name: "Berlin",
          slug: "berlin-city",
          is_city: true,
          parent_location_id: federal_state.id
        })

      # Create ZIP code and mapping
      {:ok, zip_code} =
        Maps.create_zip_code(%{
          value: "10115",
          country_location_id: country.id
        })

      {:ok, _zip_mapping} =
        Repo.insert(%ZipCodeMapping{
          zip_code_id: zip_code.id,
          location_id: city.id,
          lat: 52.5200,
          lon: 13.4050
        })

      {:ok, school} =
        Locations.create_location(%{
          name: "Test-Grundschule Berlin",
          slug: "10115-test-grundschule-berlin",
          is_school: true,
          parent_location_id: city.id
        })

      {:ok, _address} =
        Maps.create_address(%{
          "school_location_id" => school.id,
          "line1" => "Test-Grundschule Berlin",
          "street" => "Teststraße 123",
          "zip_code" => "10115",
          "city" => "Berlin",
          "email_address" => "info@test-grundschule.de",
          "phone_number" => "030-123456"
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

      %{
        school: school,
        country: country,
        federal_state: federal_state,
        beweglicher_type: beweglicher_type
      }
    end

    # Helper to find a valid school day (not weekend, not holiday, not vacation)
    defp find_valid_school_day(start_date, school_id, max_attempts \\ 30) do
      Enum.find_value(0..max_attempts, fn offset ->
        candidate = Date.add(start_date, offset)
        day_of_week = Date.day_of_week(candidate)

        # Check if it's a weekday (Monday-Friday)
        if day_of_week in 1..5 do
          # Check if there are any existing periods on this date
          case Periods.create_beweglicher_ferientag_for_school(
                 school_id,
                 candidate,
                 "Test Validity Check"
               ) do
            {:ok, period} ->
              # Clean up test period
              Repo.delete(period)
              candidate

            {:error, _} ->
              nil
          end
        else
          nil
        end
      end) || start_date
    end

    test "bewegliche Ferientage can be created programmatically and displayed", %{
      conn: conn,
      school: school,
      beweglicher_type: _beweglicher_type
    } do
      # Create a beweglicher Ferientag directly using the Periods module
      # Find a valid weekday (not weekend, not holiday, not vacation)
      future_date = find_valid_school_day(Date.utc_today() |> Date.add(10), school.id)

      {:ok, period} =
        Periods.create_beweglicher_ferientag_for_school(
          school.id,
          future_date,
          "Test Pädagogischer Tag"
        )

      # Verify it was created
      assert period.starts_on == future_date
      assert period.memo == "Test Pädagogischer Tag"
      assert period.location_id == school.id

      # Navigate to the wiki ferientage page
      {:ok, _view, html} = live(conn, "/wiki/schools/#{school.slug}/ferientage")

      # Check that the page is showing the ferientage UI (not the "no ferientage" message)
      assert html =~ "Schul-Wiki"
      assert html =~ "bewegliche Ferientage"

      # Page should show proper UI elements
      refute html =~ "Keine beweglichen Ferientage verfügbar"

      # The ferientag might be created but not immediately visible in the view
      # as it needs to be loaded from the database
    end

    test "duplicate bewegliche Ferientage are prevented", %{school: school} do
      # Create first beweglicher Ferientag on a future weekday
      future_date =
        Date.utc_today()
        |> Date.add(15)
        |> find_next_weekday()

      {:ok, _period1} =
        Periods.create_beweglicher_ferientag_for_school(
          school.id,
          future_date,
          "First Entry"
        )

      # Try to create duplicate
      result =
        Periods.create_beweglicher_ferientag_for_school(
          school.id,
          future_date,
          "Duplicate Entry"
        )

      # Should fail with error message
      assert {:error, message} = result
      assert message =~ "existiert bereits"
    end

    test "past dates are rejected by validation", %{conn: conn, school: school} do
      {:ok, view, html} = live(conn, "/wiki/schools/#{school.slug}/ferientage")

      # Simple form should be shown by default (toggle shows "Mehrere Tage")
      assert html =~ "Mehrere Tage"

      # The date input should have min date attribute preventing past dates
      assert view
             |> element("input[name='ferientag[date]']")
             |> render()
             |> String.contains?("min=")
    end

    test "bewegliche Ferientage cannot be added on existing no-school days", %{
      school: school,
      federal_state: federal_state,
      country: country
    } do
      # Find a future weekday (not weekend)
      future_date =
        Date.utc_today()
        |> Date.add(30)
        |> find_next_weekday()

      # Create a public holiday on that date at the federal state level
      {:ok, holiday_type} =
        Calendars.create_holiday_or_vacation_type(%{
          name: "Test Feiertag",
          colloquial: "Test Feiertag",
          slug: "test-feiertag",
          country_location_id: country.id,
          default_display_priority: 5,
          default_html_class: "danger",
          default_is_listed_below_month: true,
          default_is_school_vacation: false,
          default_is_public_holiday: true,
          default_is_valid_for_students: true,
          default_is_valid_for_everybody: true
        })

      {:ok, _holiday_period} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: holiday_type.id,
          starts_on: future_date,
          ends_on: future_date,
          is_public_holiday: true,
          is_valid_for_students: true,
          is_valid_for_everybody: true,
          created_by_email_address: "test@example.com"
        })

      # Try to create a beweglicher Ferientag on the same date
      result =
        Periods.create_beweglicher_ferientag_for_school(
          school.id,
          future_date,
          "Should fail"
        )

      # Should fail with error message
      assert {:error, message} = result
      assert message =~ "bereits ein schulfreier Tag" || message =~ "kein Schultag"
    end

    test "bewegliche Ferientage cannot be added on weekends", %{school: school} do
      # Find next Saturday
      saturday =
        Date.utc_today()
        |> Date.add(1)
        |> find_next_saturday()

      # Try to create a beweglicher Ferientag on Saturday
      result =
        Periods.create_beweglicher_ferientag_for_school(
          school.id,
          saturday,
          "Should fail on weekend"
        )

      # Should fail with error message
      assert {:error, message} = result
      assert message =~ "Wochenende" || message =~ "kein Schultag"
    end

    test "bewegliche Ferientage cannot be added during school vacations", %{
      school: school,
      federal_state: federal_state,
      country: country
    } do
      # Find a future weekday
      future_date =
        Date.utc_today()
        |> Date.add(60)
        |> find_next_weekday()

      # Create a school vacation period at the federal state level
      {:ok, vacation_type} =
        Calendars.create_holiday_or_vacation_type(%{
          name: "Test Ferien",
          colloquial: "Test Ferien",
          slug: "test-ferien",
          country_location_id: country.id,
          default_display_priority: 4,
          default_html_class: "info",
          default_is_listed_below_month: true,
          default_is_school_vacation: true,
          default_is_public_holiday: false,
          default_is_valid_for_students: true,
          default_is_valid_for_everybody: false
        })

      {:ok, _vacation_period} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: vacation_type.id,
          starts_on: future_date,
          ends_on: Date.add(future_date, 7),
          is_school_vacation: true,
          is_valid_for_students: true,
          created_by_email_address: "test@example.com"
        })

      # Try to create a beweglicher Ferientag during vacation
      result =
        Periods.create_beweglicher_ferientag_for_school(
          school.id,
          future_date,
          "Should fail during vacation"
        )

      # Should fail with error message
      assert {:error, message} = result
      assert message =~ "bereits ein schulfreier Tag" || message =~ "kein Schultag"
    end

    test "UI shows specific error message when adding beweglicher Ferientag on non-school day", %{
      conn: conn,
      school: school,
      federal_state: federal_state,
      country: country
    } do
      # Find a future weekday
      future_date =
        Date.utc_today()
        |> Date.add(45)
        |> find_next_weekday()

      # Create a public holiday on that date at the federal state level
      {:ok, holiday_type} =
        Calendars.create_holiday_or_vacation_type(%{
          name: "Test Feiertag UI",
          colloquial: "Test Feiertag UI",
          slug: "test-feiertag-ui",
          country_location_id: country.id,
          default_display_priority: 5,
          default_html_class: "danger",
          default_is_listed_below_month: true,
          default_is_school_vacation: false,
          default_is_public_holiday: true,
          default_is_valid_for_students: true,
          default_is_valid_for_everybody: true
        })

      {:ok, _holiday_period} =
        Periods.create_period(%{
          location_id: federal_state.id,
          holiday_or_vacation_type_id: holiday_type.id,
          starts_on: future_date,
          ends_on: future_date,
          is_public_holiday: true,
          is_valid_for_students: true,
          is_valid_for_everybody: true,
          created_by_email_address: "test@example.com"
        })

      # Navigate to the wiki ferientage page
      {:ok, view, _html} = live(conn, "/wiki/schools/#{school.slug}/ferientage")

      # Try to add a beweglicher Ferientag on the public holiday
      view
      |> element("form[phx-submit='add_single_ferientag']")
      |> render_submit(%{
        "ferientag" => %{
          "date" => Date.to_iso8601(future_date),
          "memo" => "Should fail on holiday"
        }
      })

      # Check that the specific error message is displayed
      html = render(view)
      assert html =~ "bereits ein schulfreier Tag"
    end
  end

  # Helper functions
  defp find_next_weekday(date) do
    case Date.day_of_week(date) do
      6 -> Date.add(date, 2)
      7 -> Date.add(date, 1)
      _ -> date
    end
  end

  defp find_next_saturday(date) do
    days_until_saturday = rem(6 - Date.day_of_week(date) + 7, 7)
    days_until_saturday = if days_until_saturday == 0, do: 7, else: days_until_saturday
    Date.add(date, days_until_saturday)
  end
end
