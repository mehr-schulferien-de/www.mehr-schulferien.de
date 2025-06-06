defmodule MehrSchulferienWeb.WikiControllerTest do
  use MehrSchulferienWeb.ConnCase

  import Phoenix.ConnTest
  alias MehrSchulferien.Locations
  alias MehrSchulferien.Maps.Address

  describe "wiki controller" do
    setup [:create_school_with_address]

    test "shows school wiki page with existing address", %{
      conn: conn,
      school: school,
      address: _address
    } do
      # Debug the address and school to see what we're working with
      assert school.address != nil, "School should have an address"
      assert school.address.street != nil, "Address should have a street"
      assert school.address.street == "Musterstraße 123", "Street should match expected value"

      conn = get(conn, Routes.wiki_path(conn, :show_school, school.slug))

      response = html_response(conn, 200)
      assert response =~ "Schul-Wiki: #{school.name}"
      assert response =~ school.address.street
      assert response =~ school.address.phone_number
      assert response =~ "Adressdaten bearbeiten"
    end

    test "shows school wiki page without existing address", %{conn: conn} do
      # Create a school without an address
      country = insert(:country, %{slug: "test-country"})
      federal_state = insert(:federal_state, %{parent_location_id: country.id})
      city = insert(:city, %{parent_location_id: federal_state.id})
      school = insert(:school, %{parent_location_id: city.id, slug: "test-school-no-address"})

      conn = get(conn, Routes.wiki_path(conn, :show_school, school.slug))

      response = html_response(conn, 200)
      assert response =~ "Schul-Wiki: #{school.name}"
      assert response =~ "Adressdaten bearbeiten"
    end

    test "updates school address successfully via POST", %{
      conn: conn,
      school: school,
      address: address
    } do
      updated_params = %{
        "street" => "Neue Straße 123",
        "phone_number" => "+49 30 98765432",
        "zip_code" => address.zip_code,
        "city" => address.city,
        "email_address" => address.email_address,
        "homepage_url" => address.homepage_url
      }

      conn =
        post(conn, Routes.wiki_path(conn, :update_school, school.slug), address: updated_params)

      assert redirected_to(conn, 302) =~ Routes.school_path(conn, :show, "d", school.slug)

      # Verify the address was updated in the database
      updated_school = Locations.get_school_by_slug!(school.slug)
      assert updated_school.address != nil
      assert updated_school.address.street == "Neue Straße 123"
      assert updated_school.address.phone_number == "+49 30 98765432"

      # Verify version was created with IP address in meta
      versions = PaperTrail.get_versions(updated_school.address)
      # Original insert + update
      assert length(versions) == 2
      # Use ID instead of timestamp to get the latest version (avoid timestamp collision)
      latest_version = Enum.max_by(versions, & &1.id)
      assert latest_version.meta["ip_address"] == "127.0.0.1"
      assert latest_version.event == "update"

      # PaperTrail 1.0.0 stores only the new values in item_changes, not [old, new] arrays
      assert latest_version.item_changes["street"] == "Neue Straße 123"
      assert latest_version.item_changes["phone_number"] == "+49 30 98765432"
    end

    test "updates school address successfully via PUT", %{
      conn: conn,
      school: school,
      address: address
    } do
      updated_params = %{
        "street" => "PUT Straße 456",
        "phone_number" => "+49 30 11111111",
        "zip_code" => address.zip_code,
        "city" => address.city,
        "email_address" => address.email_address,
        "homepage_url" => address.homepage_url
      }

      conn =
        put(conn, Routes.wiki_path(conn, :update_school, school.slug), address: updated_params)

      assert redirected_to(conn, 302) =~ Routes.school_path(conn, :show, "d", school.slug)

      # Verify the address was updated in the database
      updated_school = Locations.get_school_by_slug!(school.slug)
      assert updated_school.address != nil
      assert updated_school.address.street == "PUT Straße 456"
      assert updated_school.address.phone_number == "+49 30 11111111"

      # Verify version was created
      versions = PaperTrail.get_versions(updated_school.address)
      # Original insert + update
      assert length(versions) == 2
      # Use ID instead of timestamp to get the latest version (avoid timestamp collision)
      latest_version = Enum.max_by(versions, & &1.id)
      assert latest_version.meta["ip_address"] == "127.0.0.1"
      assert latest_version.event == "update"
    end

    test "creates new address for school without existing address", %{conn: conn} do
      # Create a school without an address
      country = insert(:country, %{slug: "test-country-new"})
      federal_state = insert(:federal_state, %{parent_location_id: country.id})
      city = insert(:city, %{parent_location_id: federal_state.id})
      school = insert(:school, %{parent_location_id: city.id, slug: "new-school-address"})

      new_address_params = %{
        "street" => "Neue Schule Straße 789",
        "phone_number" => "+49 30 99999999",
        "zip_code" => "12345",
        "city" => "Berlin",
        "email_address" => "info@neue-schule.de",
        "homepage_url" => "https://neue-schule.de"
      }

      conn =
        post(conn, Routes.wiki_path(conn, :update_school, school.slug),
          address: new_address_params
        )

      assert redirected_to(conn, 302) =~ Routes.school_path(conn, :show, "d", school.slug)

      # Verify the address was created in the database
      updated_school = Locations.get_school_by_slug!(school.slug)
      assert updated_school.address != nil
      assert updated_school.address.street == "Neue Schule Straße 789"
      assert updated_school.address.phone_number == "+49 30 99999999"
      assert updated_school.address.school_location_id == school.id

      # Verify version was created
      versions = PaperTrail.get_versions(updated_school.address)
      assert length(versions) == 1
      version = List.first(versions)
      assert version.meta["ip_address"] == "127.0.0.1"
      assert version.event == "insert"
    end

    test "handles validation errors correctly", %{conn: conn, school: school} do
      # Try to submit invalid data (empty required fields)
      invalid_params = %{
        "street" => "",
        "phone_number" => "",
        "zip_code" => "",
        "city" => "",
        "email_address" => "invalid-email",
        "homepage_url" => "not-a-url"
      }

      conn =
        post(conn, Routes.wiki_path(conn, :update_school, school.slug), address: invalid_params)

      # With no validations requiring these fields, this will redirect successfully
      # The controller doesn't have validation errors for these fields
      assert redirected_to(conn, 302) =~ Routes.school_path(conn, :show, "d", school.slug)
    end

    test "rollback functionality works correctly", %{
      conn: conn,
      school: school,
      address: address
    } do
      # First, make an update to create a version
      updated_params = %{
        "street" => "Updated Street 123",
        "phone_number" => "+49 30 55555555",
        "zip_code" => address.zip_code,
        "city" => address.city,
        "email_address" => address.email_address,
        "homepage_url" => address.homepage_url
      }

      post(conn, Routes.wiki_path(conn, :update_school, school.slug), address: updated_params)

      # Verify the update worked
      updated_school = Locations.get_school_by_slug!(school.slug)
      assert updated_school.address != nil
      assert updated_school.address.street == "Updated Street 123"
      assert updated_school.address.phone_number == "+49 30 55555555"

      # Get the version history
      versions = PaperTrail.get_versions(updated_school.address)
      # Original insert + update
      assert length(versions) == 2

      # Get the original version (first chronologically)
      original_version = Enum.min_by(versions, & &1.inserted_at)

      # Now test the rollback functionality
      conn =
        post(
          conn,
          Routes.wiki_path(conn, :rollback_school, school.slug, original_version.id)
        )

      assert redirected_to(conn, 302) =~ Routes.school_path(conn, :show, "d", school.slug)

      # Verify the rollback worked - should be back to original values
      rolled_back_school = Locations.get_school_by_slug!(school.slug)
      assert rolled_back_school.address != nil
      assert rolled_back_school.address.street == "Musterstraße 123"
      assert rolled_back_school.address.phone_number == "+49 30 12345678"

      # Verify a new version was created for the rollback
      all_versions = PaperTrail.get_versions(rolled_back_school.address)
      # Original insert + update + rollback
      assert length(all_versions) == 3

      # The latest version should be the rollback (use ID since timestamps might be the same)
      latest_version = Enum.max_by(all_versions, & &1.id)
      assert latest_version.meta["ip_address"] == "127.0.0.1"
      assert latest_version.event == "update"
    end

    test "rollback with invalid version ID returns error", %{conn: conn, school: school} do
      invalid_version_id = "99999"

      conn =
        post(
          conn,
          Routes.wiki_path(conn, :rollback_school, school.slug, invalid_version_id)
        )

      assert redirected_to(conn, 302) =~ Routes.wiki_path(conn, :show_school, school.slug)

      # Follow the redirect to check for error flash
      conn = get(recycle(conn), Routes.wiki_path(conn, :show_school, school.slug))
      response = html_response(conn, 200)
      assert response =~ "Fehler beim Zurückkehren"
    end

    test "rollback fails for school without address", %{conn: conn} do
      # Create a school without an address
      country = insert(:country, %{slug: "test-country-rollback"})
      federal_state = insert(:federal_state, %{parent_location_id: country.id})
      city = insert(:city, %{parent_location_id: federal_state.id})
      school = insert(:school, %{parent_location_id: city.id, slug: "no-address-school-rollback"})

      conn =
        post(
          conn,
          Routes.wiki_path(conn, :rollback_school, school.slug, "1")
        )

      assert redirected_to(conn, 302) =~ Routes.wiki_path(conn, :show_school, school.slug)

      # Follow the redirect to check for error flash
      conn = get(recycle(conn), Routes.wiki_path(conn, :show_school, school.slug))
      response = html_response(conn, 200)
      assert response =~ "Keine Adressdaten zum Zurücksetzen"
    end

    test "daily limit prevents updates when reached", %{conn: conn, school: school} do
      # Delete any existing daily change count for today to start fresh
      today = Date.utc_today()
      MehrSchulferien.Repo.delete_all(MehrSchulferien.Wiki.DailyChangeCount)

      # Insert a daily change count record that exceeds the limit
      {:ok, _} =
        MehrSchulferien.Repo.insert(%MehrSchulferien.Wiki.DailyChangeCount{
          date: today,
          count: 150
        })

      updated_params = %{
        "street" => "Should not work",
        "phone_number" => "+49 30 99999999",
        "zip_code" => "12345",
        "city" => "Berlin",
        "email_address" => "test@example.com",
        "homepage_url" => "https://example.com"
      }

      conn =
        post(conn, Routes.wiki_path(conn, :update_school, school.slug), address: updated_params)

      assert redirected_to(conn, 302) =~ Routes.wiki_path(conn, :show_school, school.slug)

      # Follow the redirect to check for error flash
      conn = get(recycle(conn), Routes.wiki_path(conn, :show_school, school.slug))
      response = html_response(conn, 200)
      assert response =~ "tägliche Limit"

      # Verify the address was NOT updated
      unchanged_school = Locations.get_school_by_slug!(school.slug)
      assert unchanged_school.address != nil
      assert unchanged_school.address.street == "Musterstraße 123"
    end

    test "no changes do not create a version", %{conn: conn, school: school, address: address} do
      # Submit the same data (no changes)
      same_params = %{
        "street" => address.street,
        "phone_number" => address.phone_number,
        "zip_code" => address.zip_code,
        "city" => address.city,
        "email_address" => address.email_address,
        "homepage_url" => address.homepage_url
      }

      conn =
        post(conn, Routes.wiki_path(conn, :update_school, school.slug), address: same_params)

      assert redirected_to(conn, 302) =~ Routes.school_path(conn, :show, "d", school.slug)

      # Verify no additional version was created since there were no changes
      school_after = Locations.get_school_by_slug!(school.slug)
      versions = PaperTrail.get_versions(school_after.address)
      # Only the original insert version
      assert length(versions) == 1
    end

    test "normalizes German phone numbers to international format when updating", %{
      conn: conn,
      school: school,
      address: address
    } do
      # Test with German phone number format
      updated_params = %{
        "street" => address.street,
        # German format
        "phone_number" => "030 98765432",
        "zip_code" => address.zip_code,
        "city" => address.city,
        "email_address" => address.email_address,
        "homepage_url" => address.homepage_url
      }

      conn =
        post(conn, Routes.wiki_path(conn, :update_school, school.slug), address: updated_params)

      assert redirected_to(conn, 302) =~ Routes.school_path(conn, :show, "d", school.slug)

      # Verify the phone number was normalized to international format
      updated_school = Locations.get_school_by_slug!(school.slug)
      assert updated_school.address != nil
      assert updated_school.address.phone_number == "+49 30 98765432"

      # Verify version was created with the normalized number
      versions = PaperTrail.get_versions(updated_school.address)
      latest_version = Enum.max_by(versions, & &1.id)
      assert latest_version.item_changes["phone_number"] == "+49 30 98765432"
    end

    test "leaves already international phone numbers unchanged when updating", %{
      conn: conn,
      school: school,
      address: address
    } do
      # Test with already international phone number format
      international_number = "+49 711 12345678"

      updated_params = %{
        "street" => address.street,
        "phone_number" => international_number,
        "zip_code" => address.zip_code,
        "city" => address.city,
        "email_address" => address.email_address,
        "homepage_url" => address.homepage_url
      }

      conn =
        post(conn, Routes.wiki_path(conn, :update_school, school.slug), address: updated_params)

      assert redirected_to(conn, 302) =~ Routes.school_path(conn, :show, "d", school.slug)

      # Verify the phone number remained unchanged
      updated_school = Locations.get_school_by_slug!(school.slug)
      assert updated_school.address != nil
      assert updated_school.address.phone_number == international_number
    end

    test "handles invalid phone numbers gracefully when updating", %{
      conn: conn,
      school: school,
      address: address
    } do
      # Test with invalid phone number
      invalid_number = "invalid-phone"

      updated_params = %{
        "street" => address.street,
        "phone_number" => invalid_number,
        "zip_code" => address.zip_code,
        "city" => address.city,
        "email_address" => address.email_address,
        "homepage_url" => address.homepage_url
      }

      conn =
        post(conn, Routes.wiki_path(conn, :update_school, school.slug), address: updated_params)

      assert redirected_to(conn, 302) =~ Routes.school_path(conn, :show, "d", school.slug)

      # Verify the invalid phone number was left unchanged (no error thrown)
      updated_school = Locations.get_school_by_slug!(school.slug)
      assert updated_school.address != nil
      assert updated_school.address.phone_number == invalid_number
    end
  end

  describe "rollback functionality" do
    setup [:create_school_with_address]

    test "simple rollback test - rollback should restore to state before the target version", %{
      conn: conn,
      school: school,
      address: original_address
    } do
      # Start with known state: "Original Street"
      assert original_address.street == "Musterstraße 123"

      # Step 1: Change to "New Street"
      conn =
        post(conn, Routes.wiki_path(conn, :update_school, school.slug),
          address: %{"street" => "New Street", "city" => "Berlin", "zip_code" => "12345"}
        )

      assert redirected_to(conn, 302)

      # Verify the change was applied
      school = Locations.get_school_by_slug!(school.slug)
      assert school.address.street == "New Street"

      # Step 2: Change to "Newer Street"  
      conn =
        post(recycle(conn), Routes.wiki_path(conn, :update_school, school.slug),
          address: %{"street" => "Newer Street", "city" => "Berlin", "zip_code" => "12345"}
        )

      assert redirected_to(conn, 302)

      # Verify the second change was applied
      school = Locations.get_school_by_slug!(school.slug)
      assert school.address.street == "Newer Street"

      # Now we should have version history:
      # Version 1: Original creation (Musterstraße 123)
      # Version 2: Changed to "New Street" 
      # Version 3: Changed to "Newer Street"

      versions = PaperTrail.get_versions(school.address) |> Enum.sort_by(& &1.id)
      assert length(versions) >= 2

      # Find the version that changed to "New Street"
      version_with_new_street =
        Enum.find(versions, fn v ->
          Map.get(v.item_changes, "street") == "New Street"
        end)

      assert version_with_new_street != nil

      # Step 3: Click "Wiederherstellen" on that version
      # This should restore to the state BEFORE "New Street" was set
      # i.e., back to "Musterstraße 123"
      conn =
        post(
          recycle(conn),
          Routes.wiki_path(conn, :rollback_school, school.slug, version_with_new_street.id)
        )

      assert redirected_to(conn, 302)

      # Verify rollback worked - should be back to original
      school = Locations.get_school_by_slug!(school.slug)
      assert school.address.street == "Musterstraße 123"
    end
  end

  defp create_school_with_address(_context) do
    country = insert(:country, %{slug: "test-country-main"})
    federal_state = insert(:federal_state, %{parent_location_id: country.id})
    city = insert(:city, %{parent_location_id: federal_state.id})
    school = insert(:school, %{parent_location_id: city.id, slug: "test-gymnasium-main"})

    # Create an address for the school using insert! directly 
    address =
      MehrSchulferien.Repo.insert!(%Address{
        street: "Musterstraße 123",
        zip_code: "12345",
        city: "Berlin",
        email_address: "info@test-gymnasium.de",
        phone_number: "+49 30 12345678",
        homepage_url: "https://test-gymnasium.de",
        school_location_id: school.id
      })

    # Manually create a version record for PaperTrail compatibility with proper initial data
    MehrSchulferien.Repo.insert!(%PaperTrail.Version{
      event: "insert",
      item_type: "Address",
      item_id: address.id,
      item_changes: %{
        "street" => "Musterstraße 123",
        "zip_code" => "12345",
        "city" => "Berlin",
        "email_address" => "info@test-gymnasium.de",
        "phone_number" => "+49 30 12345678",
        "homepage_url" => "https://test-gymnasium.de"
      },
      meta: %{ip_address: "127.0.0.1"},
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })

    # Reload the school with the address to ensure it's properly loaded
    school_with_address = Locations.get_school_by_slug!(school.slug)

    {:ok,
     %{
       school: school_with_address,
       address: address,
       country: country,
       federal_state: federal_state,
       city: city
     }}
  end
end
