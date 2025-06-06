defmodule MehrSchulferienWeb.WikiController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Locations, Maps, Wiki}
  alias MehrSchulferien.Maps.Address

  def show_school(conn, %{"slug" => school_slug}) do
    school = Locations.get_school_by_slug!(school_slug)

    # Get version history for the school's address (limit to last 4 entries)
    versions =
      if school.address do
        PaperTrail.get_versions(school.address)
        |> Enum.sort_by(& &1.inserted_at, :desc)
        |> Enum.take(4)
      else
        []
      end

    # Get daily change count
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)
    limit_reached = daily_changes >= 150

    changeset =
      if school.address do
        Maps.change_address(school.address)
      else
        Maps.change_address(%Address{school_location_id: school.id})
      end

    render(conn, "show_school.html", %{
      school: school,
      versions: versions,
      changeset: changeset,
      daily_changes: daily_changes,
      limit_reached: limit_reached,
      css_framework: :tailwind_new
    })
  end

  def update_school(conn, %{"slug" => school_slug, "address" => address_params}) do
    school = Locations.get_school_by_slug!(school_slug)

    # Check daily limit
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)

    if daily_changes >= 150 do
      conn
      |> put_flash(
        :error,
        "Das tägliche Limit von 150 Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
      )
      |> redirect(to: Routes.wiki_path(conn, :show_school, school_slug))
    else
      # Prepare address params with school_location_id
      address_params = Map.put(address_params, "school_location_id", school.id)

      result =
        if school.address do
          # Update existing address
          old_address = school.address
          changeset = Address.changeset(old_address, address_params)

          case changeset.changes do
            changes when map_size(changes) == 0 ->
              {:ok, %{model: old_address, version: nil}}

            _ ->
              PaperTrail.update(changeset, meta: %{ip_address: get_client_ip(conn)})
          end
        else
          # Create new address
          changeset = Address.changeset(%Address{}, address_params)
          PaperTrail.insert(changeset, meta: %{ip_address: get_client_ip(conn)})
        end

      case result do
        {:ok, %{model: address, version: version}} ->
          # Send email notification if there were changes
          if version do
            old_data = if school.address, do: school.address, else: %Address{}
            Wiki.send_change_notification(school, old_data, address, get_client_ip(conn))

            # Increment daily change count
            Wiki.increment_daily_change_count(today)
          end

          # Get country slug for redirect to school vacation page
          country_slug = get_country_slug_from_school(school)

          conn
          |> put_flash(:info, "Adressdaten wurden erfolgreich aktualisiert.")
          |> redirect(to: Routes.school_path(conn, :show, country_slug, school_slug))

        {:error, changeset} ->
          versions =
            if school.address do
              PaperTrail.get_versions(school.address)
              |> Enum.sort_by(& &1.inserted_at, :desc)
              |> Enum.take(4)
            else
              []
            end

          render(conn, "show_school.html", %{
            school: school,
            versions: versions,
            changeset: changeset,
            daily_changes: daily_changes,
            limit_reached: false,
            css_framework: :tailwind_new
          })
      end
    end
  end

  def rollback_school(conn, %{"slug" => school_slug, "version_id" => version_id}) do
    school = Locations.get_school_by_slug!(school_slug)

    # Check daily limit
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)

    if daily_changes >= 150 do
      conn
      |> put_flash(
        :error,
        "Das tägliche Limit von 150 Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
      )
      |> redirect(to: Routes.wiki_path(conn, :show_school, school_slug))
    else
      if school.address do
        case Wiki.rollback_to_version(school.address, version_id, get_client_ip(conn)) do
          {:ok, %{model: address, version: _version}} ->
            # Send email notification
            Wiki.send_rollback_notification(school, address, version_id, get_client_ip(conn))

            # Increment daily change count
            Wiki.increment_daily_change_count(today)

            # Get country slug for redirect to school vacation page
            country_slug = get_country_slug_from_school(school)

            conn
            |> put_flash(:info, "Erfolgreich zur ausgewählten Version zurückgekehrt.")
            |> redirect(to: Routes.school_path(conn, :show, country_slug, school_slug))

          {:error, _} ->
            conn
            |> put_flash(:error, "Fehler beim Zurückkehren zur ausgewählten Version.")
            |> redirect(to: Routes.wiki_path(conn, :show_school, school_slug))
        end
      else
        conn
        |> put_flash(:error, "Keine Adressdaten zum Zurücksetzen vorhanden.")
        |> redirect(to: Routes.wiki_path(conn, :show_school, school_slug))
      end
    end
  end

  defp get_client_ip(conn) do
    case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
      [ip | _] ->
        ip

      [] ->
        case conn.remote_ip do
          {a, b, c, d} -> "#{a}.#{b}.#{c}.#{d}"
          _ -> "unknown"
        end
    end
  end

  defp get_country_slug_from_school(school) do
    # Traverse up the hierarchy: School -> City -> County -> Federal State -> Country
    # Handle cases where the hierarchy might be incomplete in test data
    case school.parent_location_id do
      nil ->
        # Default to Germany for test cases
        "d"

      city_id ->
        city = Locations.get_location!(city_id)

        case city.parent_location_id do
          nil ->
            "d"

          county_id ->
            county = Locations.get_location!(county_id)

            case county.parent_location_id do
              nil ->
                "d"

              federal_state_id ->
                federal_state = Locations.get_location!(federal_state_id)

                case federal_state.parent_location_id do
                  nil ->
                    "d"

                  country_id ->
                    country = Locations.get_location!(country_id)
                    country.slug
                end
            end
        end
    end
  end
end
