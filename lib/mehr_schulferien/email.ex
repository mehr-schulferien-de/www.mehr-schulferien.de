defmodule MehrSchulferien.Email do
  import Swoosh.Email
  alias MehrSchulferien.UrlBuilder

  @admin_email Application.compile_env!(:mehr_schulferien, :admin_email)
  @admin_name Application.compile_env!(:mehr_schulferien, :admin_name)
  @support_email Application.compile_env!(:mehr_schulferien, :support_email)
  @noreply_email Application.compile_env!(:mehr_schulferien, :noreply_email)
  @system_email_name Application.compile_env!(:mehr_schulferien, :system_email_name)

  def welcome_email(user_email, user_name) do
    new()
    |> to({user_name, user_email})
    |> from({"MehrSchulferien", @noreply_email})
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
    |> to({"MehrSchulferien Support", @support_email})
    |> from({"MehrSchulferien Contact Form", @noreply_email})
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
    |> from({"MehrSchulferien", @noreply_email})
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
    |> from({"MehrSchulferien Test", @noreply_email})
    |> subject("Test Email von MehrSchulferien")
    |> html_body("<h1>Test Email</h1><p>Dies ist eine Test-E-Mail von MehrSchulferien.</p>")
    |> text_body("Test Email\n\nDies ist eine Test-E-Mail von MehrSchulferien.")
  end

  def school_created_notification(school, address, country_slug \\ "d") do
    school_url = UrlBuilder.school_url(country_slug, school)

    new()
    |> to({@admin_name, @admin_email})
    |> from({@system_email_name, @noreply_email})
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
    school_url = UrlBuilder.school_url(country_slug, school)
    edit_url = "https://www.mehr-schulferien.de/wiki/schools/#{school.slug}/edit"

    # Extract old name if school name was changed
    old_name = if changes["Schulname"], do: elem(changes["Schulname"], 0), else: nil

    # Build the before state (old data) from changes
    before_state = build_before_state(school, address, changes)

    new()
    |> to({@admin_name, @admin_email})
    |> from({@system_email_name, @noreply_email})
    |> subject("Schule bearbeitet: #{school.name}")
    |> html_body("""
    <h2>Schule wurde bearbeitet</h2>
    #{if old_name do
      "<p><strong>Schulname:</strong> <span style='color: #dc2626;'>#{old_name}</span> → <span style='color: #059669;'>#{school.name}</span></p>"
    else
      "<p><strong>Schulname:</strong> #{school.name}</p>"
    end}
    <p><strong>Slug:</strong> #{school.slug}</p>
    <p><strong>ID:</strong> #{school.id}</p>
    <p>
      <a href="#{school_url}" style="display: inline-block; padding: 10px 20px; background-color: #3b82f6; color: white; text-decoration: none; border-radius: 5px; margin: 10px 5px;">Schule anzeigen</a>
      <a href="#{edit_url}" style="display: inline-block; padding: 10px 20px; background-color: #10b981; color: white; text-decoration: none; border-radius: 5px; margin: 10px 5px;">Schule bearbeiten</a>
    </p>

    <h3>Alte Adressdaten (Vorher):</h3>
    #{format_address_data_html(before_state)}

    <h3>Aktuelle Adressdaten (Nachher):</h3>
    #{format_address_data_html(%{name: school.name, address: address})}

    <h3>Änderungen:</h3>
    #{format_changes_html(changes)}

    <p><strong>Bearbeitet am:</strong> #{format_datetime(DateTime.utc_now())}</p>
    """)
    |> text_body("""
    Schule wurde bearbeitet

    #{if old_name do
      "Schulname: #{old_name} → #{school.name}"
    else
      "Schulname: #{school.name}"
    end}
    Slug: #{school.slug}
    ID: #{school.id}

    Link zur Schule: #{school_url}
    Link zum Bearbeiten: #{edit_url}

    Alte Adressdaten (Vorher):
    #{format_address_data_text(before_state)}

    Aktuelle Adressdaten (Nachher):
    #{format_address_data_text(%{name: school.name, address: address})}

    Änderungen:
    #{format_changes_text(changes)}

    Bearbeitet am: #{format_datetime(DateTime.utc_now())}
    """)
  end

  defp format_datetime(%DateTime{} = datetime) do
    datetime
    |> DateTime.shift_zone!("Europe/Berlin")
    |> Calendar.strftime("%d.%m.%Y %H:%M:%S Uhr")
  end

  defp format_datetime(%NaiveDateTime{} = naive_datetime) do
    # Convert NaiveDateTime to DateTime assuming UTC, then shift to Berlin timezone
    naive_datetime
    |> DateTime.from_naive!("Etc/UTC")
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

  # Build the "before" state by reconstructing old values from changes
  defp build_before_state(school, address, changes) do
    # Map German field names to address struct keys
    field_mapping = %{
      "Straße" => :street,
      "PLZ" => :zip_code,
      "Stadt" => :city,
      "E-Mail" => :email_address,
      "Telefon" => :phone_number,
      "Homepage" => :homepage_url,
      "Schülerzeitung" => :schuelerzeitung_url,
      "Wikipedia" => :wikipedia_url,
      "Instagram" => :instagram_url,
      "Schülerzahl" => :students_count,
      "Gründungsjahr" => :founded_year,
      "Beschreibung" => :description
    }

    # Get the old name (before change)
    old_name =
      if changes["Schulname"] do
        elem(changes["Schulname"], 0)
      else
        school.name
      end

    # Build the old address by replacing changed fields with their old values
    old_address =
      if address do
        Enum.reduce(changes, address, fn {field_name, {old_value, _new_value}}, acc_address ->
          if field_key = field_mapping[field_name] do
            Map.put(acc_address, field_key, old_value)
          else
            acc_address
          end
        end)
      else
        nil
      end

    %{name: old_name, address: old_address}
  end

  # Format address data as HTML
  defp format_address_data_html(%{name: name, address: address}) do
    """
    <p><strong>Schulname:</strong> #{name || "N/A"}</p>
    #{if address do
      """
      <p><strong>Straße:</strong> #{Map.get(address, :street) || "N/A"}</p>
      <p><strong>PLZ:</strong> #{Map.get(address, :zip_code) || "N/A"}</p>
      <p><strong>Stadt:</strong> #{Map.get(address, :city) || "N/A"}</p>
      <p><strong>E-Mail:</strong> #{Map.get(address, :email_address) || "N/A"}</p>
      <p><strong>Telefon:</strong> #{Map.get(address, :phone_number) || "N/A"}</p>
      <p><strong>Homepage:</strong> #{Map.get(address, :homepage_url) || "N/A"}</p>
      <p><strong>Schülerzeitung:</strong> #{Map.get(address, :schuelerzeitung_url) || "N/A"}</p>
      <p><strong>Wikipedia:</strong> #{Map.get(address, :wikipedia_url) || "N/A"}</p>
      <p><strong>Instagram:</strong> #{Map.get(address, :instagram_url) || "N/A"}</p>
      <p><strong>Schülerzahl:</strong> #{Map.get(address, :students_count) || "N/A"}</p>
      <p><strong>Gründungsjahr:</strong> #{Map.get(address, :founded_year) || "N/A"}</p>
      <p><strong>Beschreibung:</strong> #{if Map.get(address, :description) && Map.get(address, :description) != "", do: Map.get(address, :description), else: "N/A"}</p>
      """
    else
      "<p><em>Keine Adressdaten vorhanden</em></p>"
    end}
    """
  end

  # Format address data as plain text
  defp format_address_data_text(%{name: name, address: address}) do
    """
    Schulname: #{name || "N/A"}
    #{if address do
      """
      Straße: #{Map.get(address, :street) || "N/A"}
      PLZ: #{Map.get(address, :zip_code) || "N/A"}
      Stadt: #{Map.get(address, :city) || "N/A"}
      E-Mail: #{Map.get(address, :email_address) || "N/A"}
      Telefon: #{Map.get(address, :phone_number) || "N/A"}
      Homepage: #{Map.get(address, :homepage_url) || "N/A"}
      Schülerzeitung: #{Map.get(address, :schuelerzeitung_url) || "N/A"}
      Wikipedia: #{Map.get(address, :wikipedia_url) || "N/A"}
      Instagram: #{Map.get(address, :instagram_url) || "N/A"}
      Schülerzahl: #{Map.get(address, :students_count) || "N/A"}
      Gründungsjahr: #{Map.get(address, :founded_year) || "N/A"}
      Beschreibung: #{if Map.get(address, :description) && Map.get(address, :description) != "", do: Map.get(address, :description), else: "N/A"}
      """
    else
      "Keine Adressdaten vorhanden"
    end}
    """
  end

  def school_deleted_notification(school, address, country_slug \\ "d", deletion_reason \\ nil) do
    school_url = UrlBuilder.school_url(country_slug, school)

    new()
    |> to({"Stefan Wintermeyer", "sw@wintermeyer-consulting.de"})
    |> from({@system_email_name, @noreply_email})
    |> subject("Schule gelöscht: #{school.name}")
    |> html_body("""
    <h2>Schule wurde gelöscht</h2>

    <h3>Grunddaten:</h3>
    <p><strong>Schulname:</strong> #{school.name}</p>
    <p><strong>Slug:</strong> #{school.slug}</p>
    <p><strong>ID:</strong> #{school.id}</p>
    <p><strong>Parent Location ID:</strong> #{school.parent_location_id || "N/A"}</p>
    <p><strong>Code:</strong> #{school.code || "N/A"}</p>
    <p><strong>Gelöschte URL:</strong> <span style="text-decoration: line-through;">#{school_url}</span></p>
    #{if deletion_reason && deletion_reason != "" do
      "<p><strong>Löschgrund:</strong> #{deletion_reason}</p>"
    else
      ""
    end}

    #{if address do
      """
      <h3>Adressdaten (gesichert):</h3>
      <table style="border-collapse: collapse; width: 100%; margin-top: 10px;">
        <tr><td style="padding: 5px; border: 1px solid #ddd;"><strong>Straße:</strong></td><td style="padding: 5px; border: 1px solid #ddd;">#{address.street || "N/A"}</td></tr>
        <tr><td style="padding: 5px; border: 1px solid #ddd;"><strong>PLZ:</strong></td><td style="padding: 5px; border: 1px solid #ddd;">#{address.zip_code || "N/A"}</td></tr>
        <tr><td style="padding: 5px; border: 1px solid #ddd;"><strong>Stadt:</strong></td><td style="padding: 5px; border: 1px solid #ddd;">#{address.city || "N/A"}</td></tr>
        <tr><td style="padding: 5px; border: 1px solid #ddd;"><strong>E-Mail:</strong></td><td style="padding: 5px; border: 1px solid #ddd;">#{address.email_address || "N/A"}</td></tr>
        <tr><td style="padding: 5px; border: 1px solid #ddd;"><strong>Telefon:</strong></td><td style="padding: 5px; border: 1px solid #ddd;">#{address.phone_number || "N/A"}</td></tr>
        <tr><td style="padding: 5px; border: 1px solid #ddd;"><strong>Homepage:</strong></td><td style="padding: 5px; border: 1px solid #ddd;">#{address.homepage_url || "N/A"}</td></tr>
        <tr><td style="padding: 5px; border: 1px solid #ddd;"><strong>Wikipedia:</strong></td><td style="padding: 5px; border: 1px solid #ddd;">#{address.wikipedia_url || "N/A"}</td></tr>
        <tr><td style="padding: 5px; border: 1px solid #ddd;"><strong>Instagram:</strong></td><td style="padding: 5px; border: 1px solid #ddd;">#{address.instagram_url || "N/A"}</td></tr>
        <tr><td style="padding: 5px; border: 1px solid #ddd;"><strong>Schultyp:</strong></td><td style="padding: 5px; border: 1px solid #ddd;">#{address.school_type || "N/A"}</td></tr>
        <tr><td style="padding: 5px; border: 1px solid #ddd;"><strong>Amtliche ID:</strong></td><td style="padding: 5px; border: 1px solid #ddd;">#{address.official_id || "N/A"}</td></tr>
        <tr><td style="padding: 5px; border: 1px solid #ddd;"><strong>Schülerzahl:</strong></td><td style="padding: 5px; border: 1px solid #ddd;">#{address.students_count || "N/A"}</td></tr>
        <tr><td style="padding: 5px; border: 1px solid #ddd;"><strong>Gründungsjahr:</strong></td><td style="padding: 5px; border: 1px solid #ddd;">#{address.founded_year || "N/A"}</td></tr>
        <tr><td style="padding: 5px; border: 1px solid #ddd;"><strong>Beschreibung:</strong></td><td style="padding: 5px; border: 1px solid #ddd;">#{address.description || "N/A"}</td></tr>
        #{if address.lat && address.lon do
        """
        <tr><td style="padding: 5px; border: 1px solid #ddd;"><strong>Koordinaten:</strong></td><td style="padding: 5px; border: 1px solid #ddd;">#{address.lat}, #{address.lon}</td></tr>
        """
      else
        ""
      end}
      </table>
      """
    else
      "<p><em>Keine Adressdaten vorhanden</em></p>"
    end}

    <p><strong>Gelöscht am:</strong> #{format_datetime(DateTime.utc_now())}</p>

    <div style="margin-top: 20px; padding: 15px; background-color: #fee2e2; border-left: 4px solid #dc2626;">
      <h4 style="margin-top: 0;">Wiederherstellung möglich:</h4>
      <p>Die Schule und alle zugehörigen Daten wurden in Backup-Tabellen gesichert (deleted_schools und deleted_periods).</p>
      <p>Falls die Löschung versehentlich erfolgte, können die Daten aus den Backup-Tabellen wiederhergestellt werden.</p>
    </div>

    <div style="margin-top: 20px; padding: 15px; background-color: #fef3c7; border-left: 4px solid #f59e0b;">
      <h4 style="margin-top: 0;">SQL für Wiederherstellung:</h4>
      <pre style="background-color: #f9fafb; padding: 10px; border-radius: 4px; overflow-x: auto;">
      -- Schule wiederherstellen
      INSERT INTO locations (id, name, slug, code, parent_location_id, is_school, inserted_at, updated_at)
      SELECT original_id, name, slug, code, parent_location_id, true, original_inserted_at, original_updated_at
      FROM deleted_schools WHERE original_id = #{school.id};

      -- Adresse wiederherstellen (falls vorhanden)
      #{if address do
      "INSERT INTO addresses (school_location_id, line1, street, zip_code, city, email_address, phone_number, homepage_url)\n" <> "VALUES (#{school.id}, '#{escape_sql(school.name)}', '#{escape_sql(address.street)}', '#{escape_sql(address.zip_code)}', '#{escape_sql(address.city)}', '#{escape_sql(address.email_address)}', '#{escape_sql(address.phone_number)}', '#{escape_sql(address.homepage_url)}');"
    else
      "-- Keine Adresse vorhanden"
    end}

      -- Perioden wiederherstellen
      INSERT INTO periods (id, holiday_or_vacation_type_id, location_id, starts_on, ends_on, inserted_at, updated_at)
      SELECT original_id, holiday_or_vacation_type_id, location_id, starts_on, ends_on, original_inserted_at, original_updated_at
      FROM deleted_periods WHERE deleted_school_original_id = #{school.id};
      </pre>
    </div>
    """)
    |> text_body("""
    Schule wurde gelöscht

    === GRUNDDATEN ===
    Schulname: #{school.name}
    Slug: #{school.slug}
    ID: #{school.id}
    Parent Location ID: #{school.parent_location_id || "N/A"}
    Code: #{school.code || "N/A"}
    #{if deletion_reason && deletion_reason != "", do: "Löschgrund: #{deletion_reason}\n", else: ""}
    Gelöschte URL: #{school_url}

    #{if address do
      """
      === ADRESSDATEN (GESICHERT) ===
      Straße: #{address.street || "N/A"}
      PLZ: #{address.zip_code || "N/A"}
      Stadt: #{address.city || "N/A"}
      E-Mail: #{address.email_address || "N/A"}
      Telefon: #{address.phone_number || "N/A"}
      Homepage: #{address.homepage_url || "N/A"}
      Wikipedia: #{address.wikipedia_url || "N/A"}
      Instagram: #{address.instagram_url || "N/A"}
      Schultyp: #{address.school_type || "N/A"}
      Amtliche ID: #{address.official_id || "N/A"}
      Schülerzahl: #{address.students_count || "N/A"}
      Gründungsjahr: #{address.founded_year || "N/A"}
      Beschreibung: #{address.description || "N/A"}
      #{if address.lat && address.lon do
        "Koordinaten: #{address.lat}, #{address.lon}"
      else
        ""
      end}
      """
    else
      "=== KEINE ADRESSDATEN VORHANDEN ==="
    end}

    Gelöscht am: #{format_datetime(DateTime.utc_now())}

    === WIEDERHERSTELLUNG ===
    Die Schule und alle zugehörigen Daten wurden in Backup-Tabellen gesichert (deleted_schools und deleted_periods).
    Falls die Löschung versehentlich erfolgte, können die Daten aus den Backup-Tabellen wiederhergestellt werden.
    """)
  end

  defp escape_sql(nil), do: ""
  defp escape_sql(value) when is_binary(value), do: String.replace(value, "'", "''")
  defp escape_sql(value), do: to_string(value)

  def beweglicher_ferientag_created_notification(period, school) do
    school_url = "https://www.mehr-schulferien.de/ferien/d/schule/#{school.slug}"

    new()
    |> to({@admin_name, @admin_email})
    |> from({@system_email_name, @noreply_email})
    |> subject("Neuer beweglicher Ferientag: #{school.name}")
    |> html_body("""
    <h2>Neuer beweglicher Ferientag wurde erstellt</h2>
    <p><strong>Schule:</strong> #{school.name}</p>
    <p><strong>Datum:</strong> #{Calendar.strftime(period.starts_on, "%d.%m.%Y")}</p>
    #{if period.memo, do: "<p><strong>Bemerkung:</strong> #{period.memo}</p>", else: ""}
    <p><a href="#{school_url}" style="display: inline-block; padding: 10px 20px; background-color: #3b82f6; color: white; text-decoration: none; border-radius: 5px; margin: 10px 0;">Schule anzeigen</a></p>
    """)
    |> text_body("""
    Neuer beweglicher Ferientag wurde erstellt

    Schule: #{school.name}
    Datum: #{Calendar.strftime(period.starts_on, "%d.%m.%Y")}
    #{if period.memo, do: "Bemerkung: #{period.memo}\n", else: ""}
    Link zur Schule: #{school_url}
    """)
  end

  def beweglicher_ferientag_updated_notification(period, school, changes) do
    school_url = "https://www.mehr-schulferien.de/ferien/d/schule/#{school.slug}"

    new()
    |> to({@admin_name, @admin_email})
    |> from({@system_email_name, @noreply_email})
    |> subject("Beweglicher Ferientag geändert: #{school.name}")
    |> html_body("""
    <h2>Beweglicher Ferientag wurde geändert</h2>
    <p><strong>Schule:</strong> #{school.name}</p>
    <p><strong>Datum:</strong> #{Calendar.strftime(period.starts_on, "%d.%m.%Y")}</p>
    #{if period.memo, do: "<p><strong>Bemerkung:</strong> #{period.memo}</p>", else: ""}

    <h3>Änderungen:</h3>
    #{format_changes_html(changes)}

    <p><strong>Geändert am:</strong> #{format_datetime(DateTime.utc_now())}</p>
    <p><a href="#{school_url}" style="display: inline-block; padding: 10px 20px; background-color: #3b82f6; color: white; text-decoration: none; border-radius: 5px; margin: 10px 0;">Schule anzeigen</a></p>
    """)
    |> text_body("""
    Beweglicher Ferientag wurde geändert

    Schule: #{school.name}
    Datum: #{Calendar.strftime(period.starts_on, "%d.%m.%Y")}
    #{if period.memo, do: "Bemerkung: #{period.memo}\n", else: ""}

    Änderungen:
    #{format_changes_text(changes)}

    Geändert am: #{format_datetime(DateTime.utc_now())}

    Link zur Schule: #{school_url}
    """)
  end

  def beweglicher_ferientag_deleted_notification(period, school) do
    school_url = "https://www.mehr-schulferien.de/ferien/d/schule/#{school.slug}"

    new()
    |> to({@admin_name, @admin_email})
    |> from({@system_email_name, @noreply_email})
    |> subject("Beweglicher Ferientag gelöscht: #{school.name}")
    |> html_body("""
    <h2>Beweglicher Ferientag wurde gelöscht</h2>
    <p><strong>Schule:</strong> #{school.name}</p>
    <p><strong>Datum:</strong> #{Calendar.strftime(period.starts_on, "%d.%m.%Y")}</p>
    #{if period.memo, do: "<p><strong>Bemerkung:</strong> #{period.memo}</p>", else: ""}
    <p><strong>Gelöscht am:</strong> #{format_datetime(DateTime.utc_now())}</p>
    <p><a href="#{school_url}" style="display: inline-block; padding: 10px 20px; background-color: #3b82f6; color: white; text-decoration: none; border-radius: 5px; margin: 10px 0;">Schule anzeigen</a></p>
    """)
    |> text_body("""
    Beweglicher Ferientag wurde gelöscht

    Schule: #{school.name}
    Datum: #{Calendar.strftime(period.starts_on, "%d.%m.%Y")}
    #{if period.memo, do: "Bemerkung: #{period.memo}\n", else: ""}
    Gelöscht am: #{format_datetime(DateTime.utc_now())}

    Link zur Schule: #{school_url}
    """)
  end

  def bewegliche_ferientage_bulk_copy_notification(source_school, copy_summary) do
    new()
    |> to({@admin_name, @admin_email})
    |> from({@system_email_name, @noreply_email})
    |> subject("Bewegliche Ferientage kopiert: #{source_school.name}")
    |> html_body(build_bulk_copy_html_body(source_school, copy_summary))
    |> text_body(build_bulk_copy_text_body(source_school, copy_summary))
  end

  defp build_bulk_copy_html_body(source_school, copy_summary) do
    source_school_url = "https://www.mehr-schulferien.de/ferien/d/schule/#{source_school.slug}"

    """
    <h2>Bewegliche Ferientage wurden kopiert</h2>
    <p><strong>Quellschule:</strong> <a href="#{source_school_url}">#{source_school.name}</a></p>
    <p><strong>Zeitstempel:</strong> #{format_datetime(DateTime.utc_now())}</p>

    <h3>Zusammenfassung</h3>
    <ul>
      <li><strong>Anzahl kopierte Ferientage:</strong> #{copy_summary.ferientage_count}</li>
      <li><strong>Anzahl Zielschulen:</strong> #{copy_summary.total_schools}</li>
      <li><strong>Erfolgreich kopiert:</strong> #{copy_summary.success_count} Einträge</li>
      #{if copy_summary.skip_count > 0, do: "<li><strong>Bereits vorhanden:</strong> #{copy_summary.skip_count} Einträge</li>", else: ""}
      #{if copy_summary.error_count > 0, do: "<li><strong>Fehler:</strong> #{copy_summary.error_count} Einträge</li>", else: ""}
    </ul>

    <h3>Kopierte Ferientage</h3>
    <ul>
    #{Enum.map_join(copy_summary.ferientage_details, "\n", fn detail -> "<li>#{Calendar.strftime(detail.date, "%d.%m.%Y")}#{if detail.memo, do: " - #{detail.memo}", else: ""}</li>" end)}
    </ul>

    <h3>Zielschulen</h3>
    <table style="border-collapse: collapse; width: 100%; margin-top: 10px;">
      <thead>
        <tr style="background-color: #f3f4f6;">
          <th style="border: 1px solid #e5e7eb; padding: 8px; text-align: left;">Schule</th>
          <th style="border: 1px solid #e5e7eb; padding: 8px; text-align: left;">Status</th>
          <th style="border: 1px solid #e5e7eb; padding: 8px; text-align: left;">Details</th>
        </tr>
      </thead>
      <tbody>
    #{Enum.map_join(copy_summary.school_results, "\n", fn school_result ->
      school_url = "https://www.mehr-schulferien.de/ferien/d/schule/#{school_result.school_slug}"
      status_color = case school_result.status do
        :success -> "#10b981"
        :partial -> "#f59e0b"
        :failed -> "#ef4444"
        _ -> "#6b7280"
      end

      """
        <tr>
          <td style="border: 1px solid #e5e7eb; padding: 8px;">
            <a href="#{school_url}">#{school_result.school_name}</a>
          </td>
          <td style="border: 1px solid #e5e7eb; padding: 8px;">
            <span style="color: #{status_color}; font-weight: bold;">#{format_copy_status(school_result.status)}</span>
          </td>
          <td style="border: 1px solid #e5e7eb; padding: 8px;">
            #{school_result.success_count} erfolgreich#{if school_result.skip_count > 0, do: ", #{school_result.skip_count} bereits vorhanden", else: ""}#{if school_result.error_count > 0, do: ", #{school_result.error_count} Fehler", else: ""}
          </td>
        </tr>
      """
    end)}
      </tbody>
    </table>
    """
  end

  defp build_bulk_copy_text_body(source_school, copy_summary) do
    source_school_url = "https://www.mehr-schulferien.de/ferien/d/schule/#{source_school.slug}"

    """
    Bewegliche Ferientage wurden kopiert

    Quellschule: #{source_school.name}
    Link: #{source_school_url}
    Zeitstempel: #{format_datetime(DateTime.utc_now())}

    ZUSAMMENFASSUNG
    - Anzahl kopierte Ferientage: #{copy_summary.ferientage_count}
    - Anzahl Zielschulen: #{copy_summary.total_schools}
    - Erfolgreich kopiert: #{copy_summary.success_count} Einträge
    #{if copy_summary.skip_count > 0, do: "- Bereits vorhanden: #{copy_summary.skip_count} Einträge\n", else: ""}#{if copy_summary.error_count > 0, do: "- Fehler: #{copy_summary.error_count} Einträge\n", else: ""}
    KOPIERTE FERIENTAGE
    #{Enum.map_join(copy_summary.ferientage_details, "\n", fn detail -> "- #{Calendar.strftime(detail.date, "%d.%m.%Y")}#{if detail.memo, do: " - #{detail.memo}", else: ""}" end)}

    ZIELSCHULEN
    #{Enum.map_join(copy_summary.school_results, "\n", fn school_result -> "- #{school_result.school_name}: #{format_copy_status(school_result.status)} (#{school_result.success_count} erfolgreich#{if school_result.skip_count > 0, do: ", #{school_result.skip_count} bereits vorhanden", else: ""}#{if school_result.error_count > 0, do: ", #{school_result.error_count} Fehler", else: ""})" end)}

    Links zu den Schulen:
    #{Enum.map_join(copy_summary.school_results, "\n", fn school_result -> "- #{school_result.school_name}: https://www.mehr-schulferien.de/ferien/d/schule/#{school_result.school_slug}" end)}
    """
  end

  defp format_copy_status(:success), do: "Erfolgreich"
  defp format_copy_status(:partial), do: "Teilweise erfolgreich"
  defp format_copy_status(:failed), do: "Fehlgeschlagen"
  defp format_copy_status(_), do: "Unbekannt"

  # Period notification functions
  def period_created_notification(period) do
    period = MehrSchulferien.Repo.preload(period, [:location, :holiday_or_vacation_type])

    new()
    |> to({@admin_name, @admin_email})
    |> from({@system_email_name, @noreply_email})
    |> subject(
      "Neuer Ferientermin: #{period.location.name} - #{period.holiday_or_vacation_type.name}"
    )
    |> html_body("""
    <h2>Neuer Ferientermin wurde erstellt</h2>
    <p><strong>Bundesland:</strong> #{period.location.name}</p>
    <p><strong>Ferienart:</strong> #{period.holiday_or_vacation_type.name}</p>
    <p><strong>Beginn:</strong> #{Calendar.strftime(period.starts_on, "%d.%m.%Y")}</p>
    <p><strong>Ende:</strong> #{Calendar.strftime(period.ends_on, "%d.%m.%Y")}</p>
    #{if period.memo, do: "<p><strong>Notiz:</strong> #{period.memo}</p>", else: ""}
    <p><strong>Erstellt am:</strong> #{format_datetime(DateTime.utc_now())}</p>
    <p><a href="https://www.mehr-schulferien.de/wiki/periods/#{period.id}/edit" style="display: inline-block; padding: 10px 20px; background-color: #3b82f6; color: white; text-decoration: none; border-radius: 5px; margin: 10px 0;">Termin bearbeiten</a></p>
    """)
    |> text_body("""
    Neuer Ferientermin wurde erstellt

    Bundesland: #{period.location.name}
    Ferienart: #{period.holiday_or_vacation_type.name}
    Beginn: #{Calendar.strftime(period.starts_on, "%d.%m.%Y")}
    Ende: #{Calendar.strftime(period.ends_on, "%d.%m.%Y")}
    #{if period.memo, do: "Notiz: #{period.memo}\n", else: ""}
    Erstellt am: #{format_datetime(DateTime.utc_now())}

    Link zum Bearbeiten: https://www.mehr-schulferien.de/wiki/periods/#{period.id}/edit
    """)
  end

  def period_updated_notification(period, changes) do
    period = MehrSchulferien.Repo.preload(period, [:location, :holiday_or_vacation_type])

    new()
    |> to({@admin_name, @admin_email})
    |> from({@system_email_name, @noreply_email})
    |> subject(
      "Ferientermin bearbeitet: #{period.location.name} - #{period.holiday_or_vacation_type.name}"
    )
    |> html_body("""
    <h2>Ferientermin wurde bearbeitet</h2>
    <p><strong>Bundesland:</strong> #{period.location.name}</p>
    <p><strong>Ferienart:</strong> #{period.holiday_or_vacation_type.name}</p>
    <p><strong>Aktueller Zeitraum:</strong> #{Calendar.strftime(period.starts_on, "%d.%m.%Y")} - #{Calendar.strftime(period.ends_on, "%d.%m.%Y")}</p>
    <h3>Änderungen:</h3>
    #{format_changes_html(changes)}
    <p><strong>Geändert am:</strong> #{format_datetime(DateTime.utc_now())}</p>
    <p><a href="https://www.mehr-schulferien.de/wiki/periods/#{period.id}/edit" style="display: inline-block; padding: 10px 20px; background-color: #3b82f6; color: white; text-decoration: none; border-radius: 5px; margin: 10px 0;">Termin anzeigen</a></p>
    """)
    |> text_body("""
    Ferientermin wurde bearbeitet

    Bundesland: #{period.location.name}
    Ferienart: #{period.holiday_or_vacation_type.name}
    Aktueller Zeitraum: #{Calendar.strftime(period.starts_on, "%d.%m.%Y")} - #{Calendar.strftime(period.ends_on, "%d.%m.%Y")}

    Änderungen:
    #{format_changes_text(changes)}

    Geändert am: #{format_datetime(DateTime.utc_now())}

    Link zum Termin: https://www.mehr-schulferien.de/wiki/periods/#{period.id}/edit
    """)
  end

  def period_deleted_notification(period) do
    period = MehrSchulferien.Repo.preload(period, [:location, :holiday_or_vacation_type])

    new()
    |> to({@admin_name, @admin_email})
    |> from({@system_email_name, @noreply_email})
    |> subject(
      "Ferientermin gelöscht: #{period.location.name} - #{period.holiday_or_vacation_type.name}"
    )
    |> html_body("""
    <h2>Ferientermin wurde gelöscht</h2>
    <p><strong>Bundesland:</strong> #{period.location.name}</p>
    <p><strong>Ferienart:</strong> #{period.holiday_or_vacation_type.name}</p>
    <p><strong>Zeitraum:</strong> #{Calendar.strftime(period.starts_on, "%d.%m.%Y")} - #{Calendar.strftime(period.ends_on, "%d.%m.%Y")}</p>
    #{if period.memo, do: "<p><strong>Notiz:</strong> #{period.memo}</p>", else: ""}
    <p><strong>Gelöscht am:</strong> #{format_datetime(DateTime.utc_now())}</p>
    """)
    |> text_body("""
    Ferientermin wurde gelöscht

    Bundesland: #{period.location.name}
    Ferienart: #{period.holiday_or_vacation_type.name}
    Zeitraum: #{Calendar.strftime(period.starts_on, "%d.%m.%Y")} - #{Calendar.strftime(period.ends_on, "%d.%m.%Y")}
    #{if period.memo, do: "Notiz: #{period.memo}\n", else: ""}
    Gelöscht am: #{format_datetime(DateTime.utc_now())}
    """)
  end
end
