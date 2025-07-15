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
end
