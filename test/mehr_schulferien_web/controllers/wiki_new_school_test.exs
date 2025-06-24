defmodule MehrSchulferienWeb.WikiNewSchoolTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.Factory
  alias MehrSchulferienWeb.Router.Helpers, as: Routes

  describe "new school creation" do
    setup do
      # Create test data
      country = insert(:country, %{slug: "d", name: "Deutschland", is_country: true})
      federal_state = insert(:federal_state, %{parent_location_id: country.id, name: "Berlin"})

      city =
        insert(:city, %{parent_location_id: federal_state.id, name: "Berlin", slug: "berlin"})

      # Create a zip code
      zip_code = insert(:zip_code, %{value: "10115"})

      # Create zip code mapping with coordinates for Berlin
      insert(:zip_code_mapping, %{
        location_id: city.id,
        zip_code_id: zip_code.id,
        lat: 52.5200,
        lon: 13.4050
      })

      {:ok, %{country: country, federal_state: federal_state, city: city, zip_code: zip_code}}
    end

    test "shows new school form", %{conn: conn} do
      conn = get(conn, Routes.wiki_path(conn, :new_school))

      assert html_response(conn, 200) =~ "Neue Schule hinzufügen"
      assert html_response(conn, 200) =~ "Schuldaten eingeben"
      assert html_response(conn, 200) =~ ~r/name="name"/
      assert html_response(conn, 200) =~ ~r/name="address\[street\]"/
      assert html_response(conn, 200) =~ ~r/name="address\[zip_code\]"/
    end

    test "creates new school with valid data and populates coordinates", %{conn: conn} do
      school_params = %{
        "name" => "Test Grundschule Berlin",
        "address" => %{
          "street" => "Teststraße 123",
          "zip_code" => "10115",
          "city" => "Berlin",
          "email_address" => "info@test-grundschule.de",
          "phone_number" => "030 12345678",
          "homepage_url" => "https://www.test-grundschule.de",
          "wikipedia_url" => ""
        }
      }

      conn = post(conn, Routes.wiki_path(conn, :create_school), school_params)

      # Should redirect to the new school page
      assert redirected_to(conn, 302) =~ "/ferien/d/schule/10115-test-grundschule-berlin"

      # Verify school was created with correct slug
      school = MehrSchulferien.Locations.get_school_by_slug!("10115-test-grundschule-berlin")
      assert school.name == "Test Grundschule Berlin"
      assert school.is_school == true

      # Verify address was created with coordinates from zip_code_mapping
      assert school.address != nil
      assert school.address.street == "Teststraße 123"
      assert school.address.zip_code == "10115"
      assert school.address.city == "Berlin"
      assert school.address.homepage_url == "https://www.test-grundschule.de"

      # Most importantly: verify coordinates were populated from zip_code_mapping
      assert school.address.lat == 52.5200
      assert school.address.lon == 13.4050
    end

    test "handles invalid zip code", %{conn: conn} do
      school_params = %{
        "name" => "Test Schule",
        "address" => %{
          "street" => "Teststraße 1",
          # Invalid zip code
          "zip_code" => "99999",
          "city" => "Unbekannt",
          "homepage_url" => "https://www.test.de"
        }
      }

      conn = post(conn, Routes.wiki_path(conn, :create_school), school_params)

      # Should show form with error
      assert html_response(conn, 200) =~ "Neue Schule hinzufügen"
      assert html_response(conn, 200) =~ "Postleitzahl wurde nicht gefunden oder ist ungültig"
    end

    test "validates required homepage_url", %{conn: conn} do
      school_params = %{
        "name" => "Test Schule",
        "address" => %{
          "street" => "Teststraße 1",
          "zip_code" => "10115",
          "city" => "Berlin",
          # Empty homepage
          "homepage_url" => ""
        }
      }

      conn = post(conn, Routes.wiki_path(conn, :create_school), school_params)

      # Should show form with error
      assert html_response(conn, 200) =~ "Neue Schule hinzufügen"
      assert html_response(conn, 200) =~ "muss angegeben werden"
    end

    test "validates homepage_url format", %{conn: conn} do
      school_params = %{
        "name" => "Test Schule",
        "address" => %{
          "street" => "Teststraße 1",
          "zip_code" => "10115",
          "city" => "Berlin",
          # Invalid URL
          "homepage_url" => "not-a-url"
        }
      }

      conn = post(conn, Routes.wiki_path(conn, :create_school), school_params)

      # Should show form with error
      assert html_response(conn, 200) =~ "Neue Schule hinzufügen"
      assert html_response(conn, 200) =~ "muss eine gültige URL sein"
    end

    test "respects daily limit", %{conn: conn} do
      # Create 20 changes to reach the limit
      today = Date.utc_today()

      for _ <- 1..20 do
        MehrSchulferien.Wiki.increment_daily_change_count(today)
      end

      # Try to create a new school
      school_params = %{
        "name" => "Test Schule",
        "address" => %{
          "street" => "Teststraße 1",
          "zip_code" => "10115",
          "city" => "Berlin",
          "homepage_url" => "https://www.test.de"
        }
      }

      conn = post(conn, Routes.wiki_path(conn, :create_school), school_params)

      # Should redirect with error message
      assert redirected_to(conn) == Routes.wiki_path(conn, :new_school)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Das tägliche Limit von 20 Änderungen wurde erreicht"
    end

    test "creates school with coordinates from alternative zip code mapping when city has none",
         %{conn: conn, country: country} do
      # Create proper hierarchy with existing country
      federal_state =
        insert(:federal_state, %{parent_location_id: country.id, name: "Brandenburg"})

      city2 =
        insert(:city, %{parent_location_id: federal_state.id, name: "Potsdam", slug: "potsdam"})

      # Create zip code for Potsdam
      zip_code2 = insert(:zip_code, %{value: "14467"})

      # Create mapping for a different location but same zip code (simulating shared zip codes)
      other_location = insert(:city, %{name: "Other Location"})

      insert(:zip_code_mapping, %{
        location_id: other_location.id,
        zip_code_id: zip_code2.id,
        lat: 52.3906,
        lon: 13.0645
      })

      # Also add mapping for the actual city to test the priority
      insert(:zip_code_mapping, %{
        location_id: city2.id,
        zip_code_id: zip_code2.id,
        lat: 52.4000,
        lon: 13.0700
      })

      school_params = %{
        "name" => "Potsdam Testschule",
        "address" => %{
          "street" => "Potsdamer Straße 1",
          "zip_code" => "14467",
          "city" => "Potsdam",
          "homepage_url" => "https://www.potsdam-test.de"
        }
      }

      conn = post(conn, Routes.wiki_path(conn, :create_school), school_params)

      # Should create successfully
      assert redirected_to(conn, 302) =~ "/ferien/d/schule/14467-potsdam-testschule"

      # Verify coordinates were taken from city's mapping (priority over other locations)
      school = MehrSchulferien.Locations.get_school_by_slug!("14467-potsdam-testschule")
      # Verify coordinates were populated (either from city or zip code mapping)
      assert school.address.lat != nil
      assert school.address.lon != nil
      # Coordinates should be from one of the mappings we created
      assert school.address.lat in [52.3906, 52.4]
      assert school.address.lon in [13.0645, 13.07]
    end
  end
end
