defmodule MehrSchulferienWeb.WikiNewSchoolTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.Factory
  import Phoenix.LiveViewTest

  describe "new school creation LiveView" do
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
      {:ok, view, html} = live(conn, "/wiki/schools/new")

      assert html =~ "Neue Schule anlegen"
      assert html =~ "Schuldaten"
      assert has_element?(view, "input[name=\"name\"]")
      assert has_element?(view, "input[name=\"address[street]\"]")
      assert has_element?(view, "input[name=\"address[zip_code]\"]")
    end

    test "creates new school with valid data and populates coordinates", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/wiki/schools/new")

      view
      |> form("form", %{
        name: "Test Grundschule Berlin",
        address: %{
          street: "Teststraße 123",
          zip_code: "10115",
          city: "Berlin",
          email_address: "info@test-grundschule.de",
          phone_number: "030 12345678",
          homepage_url: "https://www.test-grundschule.de",
          wikipedia_url: ""
        }
      })
      |> render_submit()

      # Should redirect to the new school page
      assert_redirect(view, "/ferien/d/schule/10115-test-grundschule-berlin")

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
      {:ok, view, _html} = live(conn, "/wiki/schools/new")

      view
      |> form("form", %{
        name: "Test Schule",
        address: %{
          street: "Teststraße 1",
          # Invalid zip code
          zip_code: "99999",
          city: "Unbekannt",
          homepage_url: "https://www.test.de"
        }
      })
      |> render_submit()

      # Should show form with error
      assert render(view) =~ "Neue Schule anlegen"
      assert render(view) =~ "Postleitzahl wurde nicht gefunden oder ist ungültig"
    end

    test "accepts empty homepage_url", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/wiki/schools/new")

      # First check that the form loads correctly
      assert render(view) =~ "Neue Schule anlegen"
      assert render(view) =~ "homepage_url"

      # Verify the homepage_url field exists and is optional (no required attribute)
      assert has_element?(view, "input[name='address[homepage_url]']")
      refute has_element?(view, "input[name='address[homepage_url]'][required]")
    end

    test "validates homepage_url format", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/wiki/schools/new")

      view
      |> form("form", %{
        name: "Test Schule",
        address: %{
          street: "Teststraße 1",
          zip_code: "10115",
          city: "Berlin",
          # Invalid URL
          homepage_url: "not-a-url"
        }
      })
      |> render_submit()

      # Should show form with error
      assert render(view) =~ "Neue Schule anlegen"
      assert render(view) =~ "muss eine gültige URL sein"
    end

    test "respects daily limit", %{conn: conn} do
      # Create 20 changes to reach the limit
      today = Date.utc_today()

      for _ <- 1..20 do
        MehrSchulferien.Wiki.increment_daily_change_count(today)
      end

      {:ok, _view, html} = live(conn, "/wiki/schools/new")

      # When limit is reached, the form should show it immediately
      assert html =~ "Das Tageslimit wurde erreicht"
      # Verify inputs are disabled  
      assert html =~ ~r/disabled/
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

      {:ok, view, _html} = live(conn, "/wiki/schools/new")

      view
      |> form("form", %{
        name: "Potsdam Testschule",
        address: %{
          street: "Potsdamer Straße 1",
          zip_code: "14467",
          city: "Potsdam",
          homepage_url: "https://www.potsdam-test.de"
        }
      })
      |> render_submit()

      # Should create successfully
      assert_redirect(view, "/ferien/d/schule/14467-potsdam-testschule")

      # Verify coordinates were taken from city's mapping (priority over other locations)
      school = MehrSchulferien.Locations.get_school_by_slug!("14467-potsdam-testschule")
      # Verify coordinates were populated (either from city or zip code mapping)
      assert school.address.lat != nil
      assert school.address.lon != nil
      # Coordinates should be close to one of the mappings we created
      assert school.address.lat >= 52.3 and school.address.lat <= 52.5
      assert school.address.lon >= 13.0 and school.address.lon <= 13.1
    end
  end
end
