defmodule MehrSchulferien.EmailTest do
  use ExUnit.Case
  import Swoosh.TestAssertions
  alias MehrSchulferien.{Email, Mailer}

  @admin_email Application.compile_env!(:mehr_schulferien, :admin_email)
  @admin_name Application.compile_env!(:mehr_schulferien, :admin_name)
  @support_email Application.compile_env!(:mehr_schulferien, :support_email)
  @noreply_email Application.compile_env!(:mehr_schulferien, :noreply_email)
  @system_email_name Application.compile_env!(:mehr_schulferien, :system_email_name)

  describe "email templates" do
    test "welcome_email/2 creates proper email" do
      email = Email.welcome_email("user@example.com", "Test User")

      assert email.to == [{"Test User", "user@example.com"}]
      assert email.from == {"MehrSchulferien", @noreply_email}
      assert email.subject == "Willkommen bei MehrSchulferien!"
      assert email.html_body =~ "Willkommen Test User!"
      assert email.text_body =~ "Willkommen Test User!"
    end

    test "contact_form_notification/4 creates proper email" do
      email =
        Email.contact_form_notification(
          "sender@example.com",
          "Sender Name",
          "Test Subject",
          "Test message content"
        )

      assert email.to == [{"MehrSchulferien Support", @support_email}]
      assert email.from == {"MehrSchulferien Contact Form", @noreply_email}
      assert email.reply_to == {"Sender Name", "sender@example.com"}
      assert email.subject == "Kontaktformular: Test Subject"
      assert email.html_body =~ "Test message content"
    end

    test "vacation_reminder/4 creates proper email" do
      email =
        Email.vacation_reminder(
          "user@example.com",
          "Test User",
          "Sommerferien",
          "01.07.2024"
        )

      assert email.to == [{"Test User", "user@example.com"}]
      assert email.from == {"MehrSchulferien", @noreply_email}
      assert email.subject == "Erinnerung: Sommerferien beginnt bald"
      assert email.html_body =~ "Sommerferien"
      assert email.html_body =~ "01.07.2024"
    end

    test "test_email/1 creates proper email" do
      email = Email.test_email("test@example.com")

      assert email.to == [{"", "test@example.com"}]
      assert email.from == {"MehrSchulferien Test", @noreply_email}
      assert email.subject == "Test Email von MehrSchulferien"
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
end
