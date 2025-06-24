defmodule MehrSchulferien.Email do
  import Swoosh.Email

  def welcome_email(user_email, user_name) do
    new()
    |> to({user_name, user_email})
    |> from({"MehrSchulferien", "noreply@mehr-schulferien.de"})
    |> subject("Willkommen bei MehrSchulferien!")
    |> html_body("""
    <h1>Willkommen #{user_name}!</h1>
    <p>Vielen Dank für Ihre Registrierung bei MehrSchulferien.</p>
    <p>Sie können jetzt alle Funktionen unserer Plattform nutzen, um Schulferien und Feiertage zu verwalten.</p>
    <p>Mit freundlichen Grüßen,<br>Ihr MehrSchulferien Team</p>
    """)
    |> text_body("""
    Willkommen #{user_name}!

    Vielen Dank für Ihre Registrierung bei MehrSchulferien.

    Sie können jetzt alle Funktionen unserer Plattform nutzen, um Schulferien und Feiertage zu verwalten.

    Mit freundlichen Grüßen,
    Ihr MehrSchulferien Team
    """)
  end

  def contact_form_notification(from_email, from_name, subject_line, message) do
    new()
    |> to({"MehrSchulferien Support", "support@mehr-schulferien.de"})
    |> from({"MehrSchulferien Contact Form", "noreply@mehr-schulferien.de"})
    |> reply_to({from_name, from_email})
    |> subject("Kontaktformular: #{subject_line}")
    |> html_body("""
    <h2>Neue Nachricht über das Kontaktformular</h2>
    <p><strong>Von:</strong> #{from_name} (#{from_email})</p>
    <p><strong>Betreff:</strong> #{subject_line}</p>
    <p><strong>Nachricht:</strong></p>
    <pre>#{message}</pre>
    """)
    |> text_body("""
    Neue Nachricht über das Kontaktformular

    Von: #{from_name} (#{from_email})
    Betreff: #{subject_line}

    Nachricht:
    #{message}
    """)
  end

  def vacation_reminder(user_email, user_name, vacation_name, start_date) do
    new()
    |> to({user_name, user_email})
    |> from({"MehrSchulferien", "noreply@mehr-schulferien.de"})
    |> subject("Erinnerung: #{vacation_name} beginnt bald")
    |> html_body("""
    <h1>Hallo #{user_name},</h1>
    <p>Dies ist eine Erinnerung, dass <strong>#{vacation_name}</strong> am <strong>#{start_date}</strong> beginnt.</p>
    <p>Vergessen Sie nicht, Ihre Reisepläne rechtzeitig zu organisieren!</p>
    <p>Mit freundlichen Grüßen,<br>Ihr MehrSchulferien Team</p>
    """)
    |> text_body("""
    Hallo #{user_name},

    Dies ist eine Erinnerung, dass #{vacation_name} am #{start_date} beginnt.

    Vergessen Sie nicht, Ihre Reisepläne rechtzeitig zu organisieren!

    Mit freundlichen Grüßen,
    Ihr MehrSchulferien Team
    """)
  end

  def test_email(recipient_email) do
    new()
    |> to(recipient_email)
    |> from({"MehrSchulferien Test", "test@mehr-schulferien.de"})
    |> subject("Test Email von MehrSchulferien")
    |> html_body("<h1>Test Email</h1><p>Dies ist eine Test-E-Mail von MehrSchulferien.</p>")
    |> text_body("Test Email\n\nDies ist eine Test-E-Mail von MehrSchulferien.")
  end
end
