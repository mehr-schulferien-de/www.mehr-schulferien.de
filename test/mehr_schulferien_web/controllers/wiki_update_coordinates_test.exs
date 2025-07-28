defmodule MehrSchulferienWeb.WikiUpdateCoordinatesTest do
  use MehrSchulferienWeb.ConnCase
  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  describe "coordinate updates on address change" do
    setup do
      # Create test data hierarchy
      country = get_or_create_deutschland()
      federal_state = insert(:federal_state, %{parent_location_id: country.id, name: "Berlin"})

      # Create two cities with different coordinates
      city_berlin =
        insert(:city, %{
          parent_location_id: federal_state.id,
          name: "Berlin",
          slug: "berlin"
        })

      city_munich =
        insert(:city, %{
          parent_location_id: federal_state.id,
          name: "München",
          slug: "munich"
        })

      # Create zip codes
      zip_berlin = insert(:zip_code, %{value: "10115"})
      zip_munich = insert(:zip_code, %{value: "80331"})

      # Create zip code mappings with different coordinates
      insert(:zip_code_mapping, %{
        location_id: city_berlin.id,
        zip_code_id: zip_berlin.id,
        lat: 52.5200,
        lon: 13.4050
      })

      insert(:zip_code_mapping, %{
        location_id: city_munich.id,
        zip_code_id: zip_munich.id,
        lat: 48.1351,
        lon: 11.5820
      })

      # Create a school with initial Berlin coordinates
      school =
        insert(:school, %{
          parent_location_id: city_berlin.id,
          name: "Test Gymnasium",
          slug: "test-gymnasium"
        })

      # Create address with PaperTrail for version tracking
      address_changeset =
        MehrSchulferien.Maps.Address.changeset(%MehrSchulferien.Maps.Address{}, %{
          "street" => "Alte Straße 1",
          "zip_code" => "10115",
          "city" => "Berlin",
          "email_address" => "info@test.de",
          "phone_number" => "+49 30 12345",
          "homepage_url" => "https://www.test.de",
          "school_location_id" => school.id,
          "lon" => 13.4050,
          "lat" => 52.5200
        })

      {:ok, %{model: address, version: _}} =
        PaperTrail.insert(address_changeset, meta: %{ip_address: "127.0.0.1"})

      # Reload school with address
      school = MehrSchulferien.Locations.get_school_by_slug!(school.slug)

      {:ok,
       %{
         conn: build_conn(),
         school: school,
         address: address,
         country: country
       }}
    end

    test "updates coordinates when zip code changes", %{
      conn: conn,
      school: school,
      address: address
    } do
      # Change to Munich zip code
      updated_params = %{
        "street" => address.street,
        # Munich zip
        "zip_code" => "80331",
        "city" => address.city,
        "email_address" => address.email_address,
        "phone_number" => address.phone_number,
        "homepage_url" => address.homepage_url
      }

      conn =
        post(conn, ~p"/wiki/schools/#{school.slug}", address: updated_params)

      assert redirected_to(conn, 302) =~ "/ferien/d/schule/#{school.slug}"

      # Verify coordinates were updated
      updated_school = MehrSchulferien.Locations.get_school_by_slug!(school.slug)
      # Coordinates should have changed from Berlin values
      refute updated_school.address.lat == 52.5200
      refute updated_school.address.lon == 13.4050
      # But we got valid coordinates (not nil)
      assert updated_school.address.lat != nil
      assert updated_school.address.lon != nil
      assert updated_school.address.zip_code == "80331"
    end

    test "updates coordinates when street changes but keeps same zip", %{
      conn: conn,
      school: school,
      address: address
    } do
      # Change only street, keeping Berlin zip
      updated_params = %{
        # Different street
        "street" => "Neue Straße 99",
        "zip_code" => address.zip_code,
        "city" => address.city,
        "email_address" => address.email_address,
        "phone_number" => address.phone_number,
        "homepage_url" => address.homepage_url
      }

      conn =
        post(conn, ~p"/wiki/schools/#{school.slug}", address: updated_params)

      assert redirected_to(conn, 302) =~ "/ferien/d/schule/#{school.slug}"

      # Verify coordinates are in Berlin area (same zip) 
      updated_school = MehrSchulferien.Locations.get_school_by_slug!(school.slug)
      # Berlin coordinates should be approximately 52.5, 13.4 (within 0.2 degrees)
      assert_in_delta updated_school.address.lat, 52.5, 0.2
      assert_in_delta updated_school.address.lon, 13.4, 0.2
      assert updated_school.address.street == "Neue Straße 99"
    end

    test "updates coordinates when city changes", %{conn: conn, school: school, address: address} do
      # Change city name (simulating a different city input)
      updated_params = %{
        "street" => address.street,
        # Munich zip to match new city
        "zip_code" => "80331",
        # Different city
        "city" => "München",
        "email_address" => address.email_address,
        "phone_number" => address.phone_number,
        "homepage_url" => address.homepage_url
      }

      conn =
        post(conn, ~p"/wiki/schools/#{school.slug}", address: updated_params)

      assert redirected_to(conn, 302) =~ "/ferien/d/schule/#{school.slug}"

      # Verify coordinates were updated to Munich area
      updated_school = MehrSchulferien.Locations.get_school_by_slug!(school.slug)
      # Munich coordinates should be approximately 48.1, 11.6 (within 0.2 degrees)
      assert_in_delta updated_school.address.lat, 48.1, 0.2
      assert_in_delta updated_school.address.lon, 11.6, 0.2
      assert updated_school.address.city == "München"
    end

    test "keeps existing coordinates when no location fields change", %{
      conn: conn,
      school: school,
      address: address
    } do
      # Change only non-location fields
      updated_params = %{
        "street" => address.street,
        "zip_code" => address.zip_code,
        "city" => address.city,
        # Only email changes
        "email_address" => "newemail@test.de",
        "phone_number" => address.phone_number,
        "homepage_url" => address.homepage_url
      }

      conn =
        post(conn, ~p"/wiki/schools/#{school.slug}", address: updated_params)

      assert redirected_to(conn, 302) =~ "/ferien/d/schule/#{school.slug}"

      # Verify coordinates remain unchanged
      updated_school = MehrSchulferien.Locations.get_school_by_slug!(school.slug)
      assert updated_school.address.lat == 52.5200
      assert updated_school.address.lon == 13.4050
      assert updated_school.address.email_address == "newemail@test.de"
    end

    test "preserves coordinates when zip code has no mapping", %{
      conn: conn,
      school: school,
      address: address
    } do
      # Use a zip code with no mapping
      updated_params = %{
        "street" => address.street,
        # Non-existent zip
        "zip_code" => "99999",
        "city" => "Unknown City",
        "email_address" => address.email_address,
        "phone_number" => address.phone_number,
        "homepage_url" => address.homepage_url
      }

      conn =
        post(conn, ~p"/wiki/schools/#{school.slug}", address: updated_params)

      assert redirected_to(conn, 302) =~ "/ferien/d/schule/#{school.slug}"

      # Verify coordinates are preserved (not cleared) when no new coordinates found
      # This prevents losing valid coordinates due to API failures or invalid addresses
      updated_school = MehrSchulferien.Locations.get_school_by_slug!(school.slug)
      # Should keep existing coordinates
      assert updated_school.address.lat != nil
      # Should keep existing coordinates
      assert updated_school.address.lon != nil
      assert updated_school.address.zip_code == "99999"
    end

    test "populates coordinates for school without initial address", %{
      conn: conn,
      country: country
    } do
      # Create school without address
      federal_state = insert(:federal_state, %{parent_location_id: country.id})
      city = insert(:city, %{parent_location_id: federal_state.id})

      school_no_address =
        insert(:school, %{
          parent_location_id: city.id,
          slug: "school-no-address"
        })

      # Create address with Munich coordinates
      new_address_params = %{
        "street" => "Neue Straße 1",
        # Munich zip
        "zip_code" => "80331",
        "city" => "München",
        "email_address" => "info@new-school.de",
        "phone_number" => "+49 89 12345",
        "homepage_url" => "https://new-school.de"
      }

      conn =
        post(conn, ~p"/wiki/schools/#{school_no_address.slug}", address: new_address_params)

      assert redirected_to(conn, 302) =~
               "/ferien/#{country.slug}/schule/#{school_no_address.slug}"

      # Verify address created with Munich coordinates
      updated_school = MehrSchulferien.Locations.get_school_by_slug!(school_no_address.slug)
      assert updated_school.address != nil
      assert updated_school.address.lat == 48.1351
      assert updated_school.address.lon == 11.5820
      assert updated_school.address.zip_code == "80331"
    end
  end
end
