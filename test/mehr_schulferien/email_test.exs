defmodule MehrSchulferien.EmailTest do
  use MehrSchulferien.DataCase
  import Swoosh.TestAssertions
  import MehrSchulferien.Factory
  alias MehrSchulferien.{Email, Mailer}

  @admin_email Application.compile_env!(:mehr_schulferien, :admin_email)
  @admin_name Application.compile_env!(:mehr_schulferien, :admin_name)
  @support_email Application.compile_env!(:mehr_schulferien, :support_email)
  @noreply_email Application.compile_env!(:mehr_schulferien, :noreply_email)
  @system_email_name Application.compile_env!(:mehr_schulferien, :system_email_name)

  describe "email templates" do
    test "contact_form_notification/4 creates proper email" do
      email =
        Email.contact_form_notification(
          "sender@example.com",
          "Sender Name",
          "Test Subject",
          "Test message content"
        )

      assert email.to == [{"mehr-schulferien.de Support", @support_email}]
      assert email.from == {"mehr-schulferien.de Contact Form", @noreply_email}
      assert email.reply_to == {"Sender Name", "sender@example.com"}
      assert email.subject == "Kontaktformular: Test Subject"
      assert email.html_body =~ "Test message content"
    end

    test "test_email/1 creates proper email" do
      email = Email.test_email("test@example.com")

      assert email.to == [{"", "test@example.com"}]
      assert email.from == {"mehr-schulferien.de Test", @noreply_email}
      assert email.subject == "Test Email von mehr-schulferien.de"
    end
  end

  describe "email delivery" do
    test "emails can be sent successfully" do
      email = Email.test_email("recipient@example.com")

      # Send email
      {:ok, _} = Mailer.deliver(email)

      # Assert email was sent (in test mode, emails are captured)
      assert_email_sent(email)
    end
  end

  describe "admin notification emails" do
    test "school_created_notification/2 creates proper email" do
      school = %{
        id: 123,
        name: "Test Grundschule",
        slug: "12345-test-grundschule",
        inserted_at: DateTime.utc_now()
      }

      address = %{
        street: "Teststraße 123",
        zip_code: "12345",
        city: "Berlin",
        email_address: "info@test-schule.de",
        phone_number: "+49 30 12345678",
        homepage_url: "https://www.test-schule.de"
      }

      email = Email.school_created_notification(school, address)

      assert email.to == [{@admin_name, @admin_email}]
      assert email.from == {@system_email_name, @noreply_email}
      assert email.subject == "Neue Schule erstellt: Test Grundschule"
      assert email.html_body =~ "Test Grundschule"
      assert email.html_body =~ "Teststraße 123"
      assert email.html_body =~ "12345"
      assert email.html_body =~ "Berlin"
    end

    test "school_updated_notification/3 creates proper email" do
      school = %{
        id: 123,
        name: "Test Grundschule",
        slug: "12345-test-grundschule"
      }

      address = %{
        street: "Neue Straße 456",
        zip_code: "12345",
        city: "Berlin",
        email_address: "neu@test-schule.de",
        phone_number: "+49 30 87654321",
        homepage_url: "https://www.neue-test-schule.de"
      }

      changes = %{
        "Straße" => {"Teststraße 123", "Neue Straße 456"},
        "E-Mail" => {"info@test-schule.de", "neu@test-schule.de"}
      }

      email = Email.school_updated_notification(school, address, changes)

      assert email.to == [{@admin_name, @admin_email}]
      assert email.from == {@system_email_name, @noreply_email}
      assert email.subject == "Schule bearbeitet: Test Grundschule"
      assert email.html_body =~ "Test Grundschule"
      assert email.html_body =~ "Neue Straße 456"
      assert email.html_body =~ "Änderungen:"
      assert email.html_body =~ "Straße:"
      assert email.html_body =~ "Teststraße 123"
      assert email.html_body =~ "Neue Straße 456"
    end

    test "school_updated_notification/3 includes old school name when name changes" do
      school = %{
        id: 123,
        name: "Neue Test Grundschule",
        slug: "12345-test-grundschule"
      }

      address = %{
        street: "Teststraße 123",
        zip_code: "12345",
        city: "Berlin",
        email_address: "info@test-schule.de",
        phone_number: "+49 30 12345678",
        homepage_url: "https://www.test-schule.de"
      }

      changes = %{
        "Schulname" => {"Alte Test Grundschule", "Neue Test Grundschule"}
      }

      email = Email.school_updated_notification(school, address, changes)

      assert email.to == [{@admin_name, @admin_email}]
      assert email.from == {@system_email_name, @noreply_email}
      assert email.subject == "Schule bearbeitet: Neue Test Grundschule"

      # Check HTML body contains both old and new names
      assert email.html_body =~ "Alte Test Grundschule"
      assert email.html_body =~ "Neue Test Grundschule"
      assert email.html_body =~ "→"

      # Check text body contains both old and new names
      assert email.text_body =~ "Alte Test Grundschule"
      assert email.text_body =~ "Neue Test Grundschule"
      assert email.text_body =~ "→"
    end

    test "school_updated_notification/3 includes complete before and after sections" do
      school = %{
        id: 123,
        name: "Neue Test Grundschule",
        slug: "12345-test-grundschule"
      }

      # Current (after) address data
      address = %{
        street: "Neue Straße 456",
        zip_code: "54321",
        city: "Hamburg",
        email_address: "neu@test-schule.de",
        phone_number: "+49 40 87654321",
        homepage_url: "https://www.neue-test-schule.de",
        schuelerzeitung_url: "https://www.neue-zeitung.de",
        wikipedia_url: "https://de.wikipedia.org/wiki/Neue_Test",
        instagram_url: "https://instagram.com/neue_test",
        students_count: 500,
        founded_year: 1990,
        description: "Neue Beschreibung"
      }

      # Changes showing old -> new values
      changes = %{
        "Schulname" => {"Alte Test Grundschule", "Neue Test Grundschule"},
        "Straße" => {"Alte Straße 123", "Neue Straße 456"},
        "PLZ" => {"12345", "54321"},
        "Stadt" => {"Berlin", "Hamburg"},
        "E-Mail" => {"alt@test-schule.de", "neu@test-schule.de"},
        "Telefon" => {"+49 30 12345678", "+49 40 87654321"},
        "Homepage" => {"https://www.alte-test-schule.de", "https://www.neue-test-schule.de"}
      }

      email = Email.school_updated_notification(school, address, changes)

      # Check HTML body contains a "before" section with old data
      assert email.html_body =~ ~r/Alte.*Adressdaten/i
      assert email.html_body =~ "Alte Straße 123"
      assert email.html_body =~ "12345"
      assert email.html_body =~ "Berlin"
      assert email.html_body =~ "alt@test-schule.de"
      assert email.html_body =~ "+49 30 12345678"
      assert email.html_body =~ "https://www.alte-test-schule.de"

      # Check HTML body contains current/after section with new data
      assert email.html_body =~ ~r/Aktuelle.*Adressdaten/i
      assert email.html_body =~ "Neue Straße 456"
      assert email.html_body =~ "54321"
      assert email.html_body =~ "Hamburg"
      assert email.html_body =~ "neu@test-schule.de"
      assert email.html_body =~ "+49 40 87654321"
      assert email.html_body =~ "https://www.neue-test-schule.de"

      # Check text body contains old data section
      assert email.text_body =~ ~r/Alte.*Adressdaten/i
      assert email.text_body =~ "Alte Straße 123"
      assert email.text_body =~ "Berlin"

      # Check text body contains new data section
      assert email.text_body =~ ~r/Aktuelle.*Adressdaten/i
      assert email.text_body =~ "Neue Straße 456"
      assert email.text_body =~ "Hamburg"
    end

    test "school notification emails can be sent" do
      school = %{
        id: 123,
        name: "Test Schule",
        slug: "test-schule",
        inserted_at: DateTime.utc_now()
      }

      address = %{
        street: "Teststraße 1",
        zip_code: "12345",
        city: "Berlin",
        email_address: nil,
        phone_number: nil,
        homepage_url: nil
      }

      # Test creation notification
      email = Email.school_created_notification(school, address)
      {:ok, _} = Mailer.deliver(email)
      assert_email_sent(email)

      # Test update notification
      changes = %{"Straße" => {"Alt", "Neu"}}
      email = Email.school_updated_notification(school, address, changes, "d")
      {:ok, _} = Mailer.deliver(email)
      assert_email_sent(email)
    end
  end

  describe "bewegliche ferientage emails" do
    test "bewegliche_ferientage_bulk_copy_notification/2 creates proper email" do
      source_school = %{
        id: 100,
        name: "Quelle Grundschule",
        slug: "quelle-grundschule"
      }

      copy_summary = %{
        ferientage_count: 3,
        total_schools: 2,
        success_count: 5,
        skip_count: 1,
        error_count: 0,
        ferientage_details: [
          %{date: ~D[2025-02-14], memo: "Beweglicher Ferientag"},
          %{date: ~D[2025-05-30], memo: "Brückentag"},
          %{date: ~D[2025-10-03], memo: nil}
        ],
        school_results: [
          %{
            school_id: 101,
            school_name: "Ziel Grundschule 1",
            school_slug: "ziel-grundschule-1",
            status: :success,
            success_count: 3,
            skip_count: 0,
            error_count: 0
          },
          %{
            school_id: 102,
            school_name: "Ziel Grundschule 2",
            school_slug: "ziel-grundschule-2",
            status: :partial,
            success_count: 2,
            skip_count: 1,
            error_count: 0
          }
        ]
      }

      email = Email.bewegliche_ferientage_bulk_copy_notification(source_school, copy_summary)

      assert email.to == [{@admin_name, @admin_email}]
      assert email.from == {@system_email_name, @noreply_email}
      assert email.subject == "Bewegliche Ferientage kopiert: Quelle Grundschule"

      # Check HTML body content
      assert email.html_body =~ "Quelle Grundschule"
      assert email.html_body =~ "Anzahl kopierte Ferientage:</strong> 3"
      assert email.html_body =~ "Anzahl Zielschulen:</strong> 2"
      assert email.html_body =~ "Erfolgreich kopiert:</strong> 5"
      assert email.html_body =~ "Bereits vorhanden:</strong> 1"
      assert email.html_body =~ "14.02.2025 - Beweglicher Ferientag"
      assert email.html_body =~ "30.05.2025 - Brückentag"
      assert email.html_body =~ "03.10.2025"
      assert email.html_body =~ "Ziel Grundschule 1"
      assert email.html_body =~ "Ziel Grundschule 2"
      assert email.html_body =~ "Erfolgreich"
      assert email.html_body =~ "Teilweise erfolgreich"

      # Check text body content
      assert email.text_body =~ "Quelle Grundschule"
      assert email.text_body =~ "Anzahl kopierte Ferientage: 3"
      assert email.text_body =~ "ZIELSCHULEN"
    end

    test "bewegliche_ferientage_bulk_copy_notification email can be sent" do
      source_school = %{
        id: 100,
        name: "Test Schule",
        slug: "test-schule"
      }

      copy_summary = %{
        ferientage_count: 1,
        total_schools: 1,
        success_count: 1,
        skip_count: 0,
        error_count: 0,
        ferientage_details: [
          %{date: ~D[2025-02-14], memo: "Test"}
        ],
        school_results: [
          %{
            school_id: 101,
            school_name: "Ziel Schule",
            school_slug: "ziel-schule",
            status: :success,
            success_count: 1,
            skip_count: 0,
            error_count: 0
          }
        ]
      }

      email = Email.bewegliche_ferientage_bulk_copy_notification(source_school, copy_summary)
      {:ok, _} = Mailer.deliver(email)
      assert_email_sent(email)
    end
  end

  describe "pending change notification emails" do
    test "update_school email contains wiki school URL" do
      school =
        insert(:school, name: "Albert-Einstein-Gymnasium", slug: "albert-einstein-gymnasium")

      insert(:address, school_location_id: school.id, street: "Schulstraße 1", city: "Berlin")

      pending_change = %{
        change_type: "update_school",
        original_record_id: school.id,
        payload: %{
          "school_name" => "Albert-Einstein-Gymnasium",
          "address_params" => %{"street" => "Neue Straße 5"}
        },
        approval_token: "approve-token-123",
        rejection_token: "reject-token-456",
        inserted_at: DateTime.utc_now(),
        submitted_by_ip: "127.0.0.1"
      }

      email = Email.pending_change_notification(pending_change)

      assert email.html_body =~ "/wiki/schools/albert-einstein-gymnasium"
      assert email.text_body =~ "/wiki/schools/albert-einstein-gymnasium"
    end

    test "update_school email contains before/after values with arrow" do
      school = insert(:school, name: "Test Schule", slug: "test-schule")

      insert(:address,
        school_location_id: school.id,
        street: "Alte Straße 1",
        city: "Berlin",
        zip_code: "10115"
      )

      pending_change = %{
        change_type: "update_school",
        original_record_id: school.id,
        payload: %{
          "school_name" => "Test Schule",
          "address_params" => %{"street" => "Neue Straße 99", "city" => "Hamburg"}
        },
        approval_token: "approve-token-123",
        rejection_token: "reject-token-456",
        inserted_at: DateTime.utc_now(),
        submitted_by_ip: "127.0.0.1"
      }

      email = Email.pending_change_notification(pending_change)

      # HTML should contain before/after with arrow
      assert email.html_body =~ "Alte Straße 1"
      assert email.html_body =~ "Neue Straße 99"
      assert email.html_body =~ "→"
      assert email.html_body =~ "Berlin"
      assert email.html_body =~ "Hamburg"

      # Text should contain before/after with arrow
      assert email.text_body =~ "Alte Straße 1"
      assert email.text_body =~ "Neue Straße 99"
      assert email.text_body =~ "→"
    end

    test "update_school email contains full school name from DB" do
      school = insert(:school, name: "Friedrich-Schiller-Gymnasium Berlin", slug: "fsg-berlin")
      insert(:address, school_location_id: school.id, street: "Schulweg 10")

      pending_change = %{
        change_type: "update_school",
        original_record_id: school.id,
        payload: %{
          "school_name" => "Friedrich-Schiller-Gymnasium Berlin",
          "address_params" => %{"street" => "Neuer Schulweg 20"}
        },
        approval_token: "approve-token-123",
        rejection_token: "reject-token-456",
        inserted_at: DateTime.utc_now(),
        submitted_by_ip: "127.0.0.1"
      }

      email = Email.pending_change_notification(pending_change)

      assert email.html_body =~ "Friedrich-Schiller-Gymnasium Berlin"
      assert email.text_body =~ "Friedrich-Schiller-Gymnasium Berlin"
    end

    test "update_school with non-existent school falls back gracefully" do
      pending_change = %{
        change_type: "update_school",
        original_record_id: -1,
        payload: %{
          "school_name" => "Ghost School",
          "address_params" => %{"street" => "Nowhere St"}
        },
        approval_token: "approve-token-123",
        rejection_token: "reject-token-456",
        inserted_at: DateTime.utc_now(),
        submitted_by_ip: "127.0.0.1"
      }

      email = Email.pending_change_notification(pending_change)

      # Should not crash, should show fallback content
      assert email.html_body =~ "Ghost School"
      assert email.html_body =~ "Schule nicht in der Datenbank gefunden"
    end

    test "delete_school email contains school URL" do
      school = insert(:school, name: "Zu löschende Schule", slug: "zu-loeschende-schule")
      insert(:address, school_location_id: school.id, street: "Abbruchstraße 1")

      pending_change = %{
        change_type: "delete_school",
        original_record_id: school.id,
        payload: %{
          "school_name" => "Zu löschende Schule",
          "deletion_reason" => "Schule geschlossen"
        },
        approval_token: "approve-token-123",
        rejection_token: "reject-token-456",
        inserted_at: DateTime.utc_now(),
        submitted_by_ip: "127.0.0.1"
      }

      email = Email.pending_change_notification(pending_change)

      assert email.html_body =~ "/wiki/schools/zu-loeschende-schule"
      assert email.text_body =~ "/wiki/schools/zu-loeschende-schule"
    end
  end
end
