defmodule MehrSchulferien.EmailTest do
  use ExUnit.Case
  import Swoosh.TestAssertions
  alias MehrSchulferien.{Email, Mailer}

  describe "email templates" do
    test "welcome_email/2 creates proper email" do
      email = Email.welcome_email("user@example.com", "Test User")

      assert email.to == [{"Test User", "user@example.com"}]
      assert email.from == {"MehrSchulferien", "noreply@mehr-schulferien.de"}
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

      assert email.to == [{"MehrSchulferien Support", "support@mehr-schulferien.de"}]
      assert email.from == {"MehrSchulferien Contact Form", "noreply@mehr-schulferien.de"}
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
      assert email.from == {"MehrSchulferien", "noreply@mehr-schulferien.de"}
      assert email.subject == "Erinnerung: Sommerferien beginnt bald"
      assert email.html_body =~ "Sommerferien"
      assert email.html_body =~ "01.07.2024"
    end

    test "test_email/1 creates proper email" do
      email = Email.test_email("test@example.com")

      assert email.to == [{"", "test@example.com"}]
      assert email.from == {"MehrSchulferien Test", "test@mehr-schulferien.de"}
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
end
