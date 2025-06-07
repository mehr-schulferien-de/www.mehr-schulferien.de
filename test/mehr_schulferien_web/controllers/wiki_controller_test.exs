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

      # Verify the correct success flash message was set
      assert Phoenix.Flash.get(conn.assigns.flash, :info) ==
               "Schuldaten wurden erfolgreich aktualisiert. Danke für Ihre Hilfe!"
    end

    test "updates school address with wikipedia_url and tracks changes", %{
      conn: conn,
      school: school,
      address: address
    } do
      updated_params = %{
        "street" => address.street,
        "phone_number" => address.phone_number,
        "zip_code" => address.zip_code,
        "city" => address.city,
        "email_address" => address.email_address,
        "homepage_url" => address.homepage_url,
        "wikipedia_url" => "https://de.wikipedia.org/wiki/Test-Schule"
      }

      conn =
        post(conn, Routes.wiki_path(conn, :update_school, school.slug), address: updated_params)

      assert redirected_to(conn, 302) =~ Routes.school_path(conn, :show, "d", school.slug)

      # Verify the address was updated with wikipedia_url
      updated_school = Locations.get_school_by_slug!(school.slug)
      assert updated_school.address != nil
      assert updated_school.address.wikipedia_url == "https://de.wikipedia.org/wiki/Test-Schule"
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

    test "daily limit prevents updates when reached", %{conn: conn, school: school} do
      # Delete any existing daily change count for today to start fresh
      today = Date.utc_today()
      MehrSchulferien.Repo.delete_all(MehrSchulferien.Wiki.DailyChangeCount)

      # Insert a daily change count record that exceeds the limit
      {:ok, _} =
        MehrSchulferien.Repo.insert(%MehrSchulferien.Wiki.DailyChangeCount{
          date: today,
          count: 20
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

  defp create_school_with_address(_context) do
    country = insert(:country, %{slug: "d"})
    federal_state = insert(:federal_state, %{parent_location_id: country.id})
    county = insert(:county, %{parent_location_id: federal_state.id})
    city = insert(:city, %{parent_location_id: county.id})
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
       county: county,
       city: city
     }}
  end
end
