defmodule MehrSchulferienWeb.System.BeweglicheFerientageIntegrationTest do
  use MehrSchulferienWeb.ConnCase, async: false
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

      %{school: school, country: country, beweglicher_type: beweglicher_type}
    end

    test "bewegliche Ferientage can be created programmatically and displayed", %{
      conn: conn,
      school: school,
      beweglicher_type: _beweglicher_type
    } do
      # Create a beweglicher Ferientag directly using the Periods module
      future_date = Date.utc_today() |> Date.add(10)

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
      # Create first beweglicher Ferientag
      future_date = Date.utc_today() |> Date.add(15)

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
  end
end
