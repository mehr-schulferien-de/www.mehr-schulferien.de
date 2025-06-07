defmodule MehrSchulferienWeb.System.WikiVersionDisplayTest do
  use MehrSchulferienWeb.ConnCase, async: false

  import MehrSchulferien.Factory

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Maps.Address

  describe "complete version history display" do
    setup [:create_school_with_initial_data]

    @tag :system
    test "displays complete old dataset in version history with email missing but highlighted", %{
      conn: conn,
      school: school,
      original_address: original_address
    } do
      # Step 1: Verify initial state - school has name, street, zip_code, city (but no email)
      assert school.name == "Test Gymnasium"
      assert original_address.street == "Hauptstraße 123"
      assert original_address.zip_code == "12345"
      assert original_address.city == "Berlin"
      assert is_nil(original_address.email_address) || original_address.email_address == ""

      # Step 2: Visit the wiki page and add an email address
      conn = get(conn, Routes.wiki_path(conn, :show_school, school.slug))
      response = html_response(conn, 200)

      # Verify we can see the form
      assert response =~ "Adressdaten bearbeiten"
      assert response =~ school.name
      assert response =~ original_address.street

      # Step 3: Add an email address (keeping all other data the same)
      updated_params = %{
        "street" => original_address.street,
        "zip_code" => original_address.zip_code,
        "city" => original_address.city,
        "phone_number" => original_address.phone_number || "",
        "homepage_url" => original_address.homepage_url || "",
        "wikipedia_url" => original_address.wikipedia_url || "",
        # This is the new field we're adding
        "email_address" => "new@example.com"
      }

      conn =
        post(conn, Routes.wiki_path(conn, :update_school, school.slug), address: updated_params)

      assert redirected_to(conn, 302)

      # Step 4: Reopen the wiki and examine the version history
      conn = get(conn, Routes.wiki_path(conn, :show_school, school.slug))
      response = html_response(conn, 200)

      # Verify the email was added
      assert response =~ "new@example.com"

      # Verify version history section exists
      assert response =~ "Versionshistorie"

      # Step 5: Get the versions to understand what we're testing
      updated_school = Locations.get_school_by_slug!(school.slug)
      versions = PaperTrail.get_versions(updated_school.address) |> Enum.sort_by(& &1.id, :desc)

      # Should have 2 versions: original insert + email update
      assert length(versions) == 2

      [latest_version, _original_version] = versions

      # Step 6: Verify the latest version shows the COMPLETE OLD dataset 
      # (what you would get if you rolled back to before this version)

      # The version display should show the complete state before the email was added
      # This includes all the original data: name, street, zip_code, city
      # The email should be missing (shown as empty) but highlighted in yellow

      # Check that all original fields are visible in the version history
      # Name should be shown
      assert response =~ "Test Gymnasium"
      # Street should be shown  
      assert response =~ original_address.street
      # ZIP code should be shown
      assert response =~ original_address.zip_code
      # City should be shown
      assert response =~ original_address.city

      # Check that the missing email field is highlighted in yellow (bg-yellow-100)
      # This should appear in the version history display
      assert response =~ "bg-yellow-100"

      # Step 7: Verify the version history shows what rollback would restore
      # The user should be able to see the complete old dataset, not just changed fields

      # Extract the version history section for the latest version
      latest_version_pattern = ~r/Version ##{latest_version.id}.*?(?=Version #|\z)/s

      case Regex.run(latest_version_pattern, response) do
        [version_html] ->
          # The version should show the complete old dataset
          assert version_html =~ original_address.street
          assert version_html =~ original_address.zip_code
          assert version_html =~ original_address.city

          # The email field should be present but empty/missing, and highlighted
          # (This represents the state before email was added)
          assert version_html =~ "bg-yellow-100"

        nil ->
          flunk("Could not find version history section for version #{latest_version.id}")
      end

      # Step 8: Verify the user can see what rollback will restore
      # The complete old dataset should be visible, showing exactly what they'll get back

      # The version history should function as a preview of what "Wiederherstellen" will restore
      # All fields should be visible (not just the changed ones)
      assert response =~ "Wiederherstellen"

      # This test demonstrates that:
      # 1. Users can see the complete old dataset in version history
      # 2. Missing fields (like email) are highlighted in yellow
      # 3. All original data (name, street, zip_code, city) is visible
      # 4. The version history serves as a preview of what rollback will restore
      # 5. Users get the complete context, not just diffs
    end
  end

  defp create_school_with_initial_data(_) do
    # Create a school with initial complete data (name, street, zip_code, city)
    # but without email address initially
    country = insert(:country, %{slug: "d", name: "Deutschland"})

    federal_state =
      insert(:federal_state, %{
        parent_location_id: country.id,
        slug: "bayern",
        name: "Bayern"
      })

    city =
      insert(:city, %{
        parent_location_id: federal_state.id,
        slug: "test-city",
        name: "Berlin"
      })

    school =
      insert(:school, %{
        parent_location_id: city.id,
        slug: "test-gymnasium-version-display",
        name: "Test Gymnasium"
      })

    # Create address with initial data but NO email address
    # This simulates a school that has basic data but is missing some fields
    address_changeset =
      Address.changeset(%Address{}, %{
        "street" => "Hauptstraße 123",
        "zip_code" => "12345",
        "city" => "Berlin",
        "phone_number" => "+49 30 123456789",
        "homepage_url" => "https://test-gymnasium.de",
        "wikipedia_url" => "",
        # Initially empty - this is what we'll add later
        "email_address" => "",
        "school_location_id" => school.id
      })

    {:ok, %{model: address, version: _version}} =
      PaperTrail.insert(address_changeset, meta: %{ip_address: "127.0.0.1"})

    # Reload school to ensure address relationship is loaded
    school_with_address = Locations.get_school_by_slug!(school.slug)

    {:ok, %{school: school_with_address, original_address: address}}
  end
end
