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

  def school_created_notification(school, address, country_slug \\ "d") do
    school_url = "https://www.mehr-schulferien.de/ferien/#{country_slug}/schule/#{school.slug}"

    new()
    |> to({"Stefan Wintermeyer", "sw@wintermeyer-consulting.de"})
    |> from({"MehrSchulferien System", "noreply@mehr-schulferien.de"})
    |> subject("Neue Schule erstellt: #{school.name}")
    |> html_body("""
    <h2>Neue Schule wurde erstellt</h2>
    <p><strong>Schulname:</strong> #{school.name}</p>
    <p><strong>Slug:</strong> #{school.slug}</p>
    <p><strong>ID:</strong> #{school.id}</p>
    <p><a href="#{school_url}" style="display: inline-block; padding: 10px 20px; background-color: #3b82f6; color: white; text-decoration: none; border-radius: 5px; margin: 10px 0;">Schule anzeigen</a></p>
    #{if address do
      """
      <h3>Adressdaten:</h3>
      <p><strong>Straße:</strong> #{address.street || "N/A"}</p>
      <p><strong>PLZ:</strong> #{address.zip_code || "N/A"}</p>
      <p><strong>Stadt:</strong> #{address.city || "N/A"}</p>
      <p><strong>E-Mail:</strong> #{address.email_address || "N/A"}</p>
      <p><strong>Telefon:</strong> #{address.phone_number || "N/A"}</p>
      <p><strong>Homepage:</strong> #{address.homepage_url || "N/A"}</p>
      """
    else
      "<p><em>Keine Adressdaten vorhanden</em></p>"
    end}
    <p><strong>Erstellt am:</strong> #{format_datetime(school.inserted_at)}</p>
    """)
    |> text_body("""
    Neue Schule wurde erstellt

    Schulname: #{school.name}
    Slug: #{school.slug}
    ID: #{school.id}

    Link zur Schule: #{school_url}

    #{if address do
      """

      Adressdaten:
      Straße: #{address.street || "N/A"}
      PLZ: #{address.zip_code || "N/A"}
      Stadt: #{address.city || "N/A"}
      E-Mail: #{address.email_address || "N/A"}
      Telefon: #{address.phone_number || "N/A"}
      Homepage: #{address.homepage_url || "N/A"}
      """
    else
      "\nKeine Adressdaten vorhanden"
    end}

    Erstellt am: #{format_datetime(school.inserted_at)}
    """)
  end

  def school_updated_notification(school, address, changes, country_slug \\ "d") do
    school_url = "https://www.mehr-schulferien.de/ferien/#{country_slug}/schule/#{school.slug}"

    new()
    |> to({"Stefan Wintermeyer", "sw@wintermeyer-consulting.de"})
    |> from({"MehrSchulferien System", "noreply@mehr-schulferien.de"})
    |> subject("Schule bearbeitet: #{school.name}")
    |> html_body("""
    <h2>Schule wurde bearbeitet</h2>
    <p><strong>Schulname:</strong> #{school.name}</p>
    <p><strong>Slug:</strong> #{school.slug}</p>
    <p><strong>ID:</strong> #{school.id}</p>
    <p><a href="#{school_url}" style="display: inline-block; padding: 10px 20px; background-color: #3b82f6; color: white; text-decoration: none; border-radius: 5px; margin: 10px 0;">Schule anzeigen</a></p>

    <h3>Aktuelle Adressdaten:</h3>
    #{if address do
      """
      <p><strong>Straße:</strong> #{address.street || "N/A"}</p>
      <p><strong>PLZ:</strong> #{address.zip_code || "N/A"}</p>
      <p><strong>Stadt:</strong> #{address.city || "N/A"}</p>
      <p><strong>E-Mail:</strong> #{address.email_address || "N/A"}</p>
      <p><strong>Telefon:</strong> #{address.phone_number || "N/A"}</p>
      <p><strong>Homepage:</strong> #{address.homepage_url || "N/A"}</p>
      """
    else
      "<p><em>Keine Adressdaten vorhanden</em></p>"
    end}

    <h3>Änderungen:</h3>
    #{format_changes_html(changes)}

    <p><strong>Bearbeitet am:</strong> #{format_datetime(DateTime.utc_now())}</p>
    """)
    |> text_body("""
    Schule wurde bearbeitet

    Schulname: #{school.name}
    Slug: #{school.slug}
    ID: #{school.id}

    Link zur Schule: #{school_url}

    Aktuelle Adressdaten:
    #{if address do
      """
      Straße: #{address.street || "N/A"}
      PLZ: #{address.zip_code || "N/A"}
      Stadt: #{address.city || "N/A"}
      E-Mail: #{address.email_address || "N/A"}
      Telefon: #{address.phone_number || "N/A"}
      Homepage: #{address.homepage_url || "N/A"}
      """
    else
      "Keine Adressdaten vorhanden"
    end}

    Änderungen:
    #{format_changes_text(changes)}

    Bearbeitet am: #{format_datetime(DateTime.utc_now())}
    """)
  end

  defp format_datetime(datetime) do
    datetime
    |> DateTime.shift_zone!("Europe/Berlin")
    |> Calendar.strftime("%d.%m.%Y %H:%M:%S Uhr")
  end

  defp format_changes_html(changes) when is_map(changes) do
    changes
    |> Enum.map(fn {field, {old, new}} ->
      cond do
        old == "" || old == nil ->
          "<p><strong>#{humanize_field(field)}:</strong> <span style='color: #666;'>(neu)</span> → <span style='color: #059669;'>#{new || "leer"}</span></p>"

        old == new ->
          "<p><strong>#{humanize_field(field)}:</strong> <span style='color: #666;'>#{old}</span> (unverändert)</p>"

        true ->
          "<p><strong>#{humanize_field(field)}:</strong> <span style='color: #dc2626;'>#{old}</span> → <span style='color: #059669;'>#{new || "leer"}</span></p>"
      end
    end)
    |> Enum.join("\n")
  end

  defp format_changes_html(_), do: "<p>Keine Änderungen verfügbar</p>"

  defp format_changes_text(changes) when is_map(changes) do
    changes
    |> Enum.map(fn {field, {old, new}} ->
      cond do
        old == "" || old == nil ->
          "#{humanize_field(field)}: (neu) → #{new || "leer"}"

        old == new ->
          "#{humanize_field(field)}: #{old} (unverändert)"

        true ->
          "#{humanize_field(field)}: #{old} → #{new || "leer"}"
      end
    end)
    |> Enum.join("\n")
  end

  defp format_changes_text(_), do: "Keine Änderungen verfügbar"

  defp humanize_field(field) do
    field
    |> to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
