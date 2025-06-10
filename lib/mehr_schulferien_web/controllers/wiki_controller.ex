defmodule MehrSchulferienWeb.WikiController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Locations, Maps, Wiki}
  alias MehrSchulferien.Maps.Address

  def show_school(conn, %{"slug" => school_slug}) do
    school = Locations.get_school_by_slug!(school_slug)

    # Get combined version history for both school and address (limit to last 4 entries)
    versions = get_combined_versions(school)

    # Get daily change count
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)
    limit_reached = daily_changes >= 20

    # Create a combined changeset for both school and address fields
    changeset =
      if school.address do
        # Merge school and address changesets into one form
        address_changeset = Maps.change_address(school.address)
        %{address_changeset | data: Map.merge(address_changeset.data, %{name: school.name})}
      else
        # Create address changeset with school name
        address_changeset = Maps.change_address(%Address{school_location_id: school.id})
        %{address_changeset | data: Map.merge(address_changeset.data, %{name: school.name})}
      end

    render(conn, "show_school.html", %{
      school: school,
      versions: versions,
      display_versions: Enum.take(versions, 5),
      changeset: changeset,
      daily_changes: daily_changes,
      limit_reached: limit_reached,
      css_framework: :tailwind_new
    })
  end

  def update_school(conn, %{"slug" => school_slug} = params) do
    school = Locations.get_school_by_slug!(school_slug)

    # Check daily limit
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)

    if daily_changes >= 20 do
      conn
      |> put_flash(
        :error,
        "Das tägliche Limit von 20 Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
      )
      |> redirect(to: Routes.wiki_path(conn, :show_school, school_slug))
    else
      # Extract school and address params
      school_params = Map.take(params, ["name"])
      address_params = Map.get(params, "address", %{})

      # Update school name if provided
      school_result =
        if Map.has_key?(school_params, "name") and school_params["name"] != school.name do
          # Prepare updated name for both school location and address line1
          name = school_params["name"]
          location_changeset = MehrSchulferien.Locations.Location.changeset(school, %{name: name})
          PaperTrail.update(location_changeset, meta: %{ip_address: get_client_ip(conn)})
        else
          {:ok, %{model: school, version: nil}}
        end

      # Handle address update/creation
      address_result =
        case school_result do
          {:ok, %{model: updated_school, version: _school_version}} ->
            # Prepare address params with school_location_id and line1
            address_params =
              address_params
              |> Map.put("school_location_id", updated_school.id)
              |> maybe_update_line1(school_params["name"])

            if updated_school.address do
              # Update existing address
              old_address = updated_school.address
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

          error ->
            error
        end

      case {school_result, address_result} do
        {{:ok, %{model: updated_school, version: school_version}},
         {:ok, %{model: _address, version: address_version}}} ->
          # Send email notification if there were changes
          if school_version || address_version do
            # Increment daily change count
            Wiki.increment_daily_change_count(today)
          end

          # Get country slug for redirect to school vacation page
          country_slug = get_country_slug_from_school(updated_school)

          # Show different message based on whether changes were made
          flash_message =
            if school_version || address_version do
              "Schuldaten wurden erfolgreich aktualisiert. Danke für Ihre Hilfe!"
            else
              "Keine Änderungen vorgenommen - die Daten waren bereits aktuell."
            end

          conn
          |> put_flash(:info, flash_message)
          |> redirect(to: Routes.school_path(conn, :show, country_slug, school_slug))

        {{:error, changeset}, _} ->
          # School update failed
          versions = get_combined_versions(school)

          render(conn, "show_school.html", %{
            school: school,
            versions: versions,
            display_versions: Enum.take(versions, 5),
            changeset: changeset,
            daily_changes: daily_changes,
            limit_reached: false,
            css_framework: :tailwind_new
          })

        {_, {:error, changeset}} ->
          # Address update failed
          versions = get_combined_versions(school)

          render(conn, "show_school.html", %{
            school: school,
            versions: versions,
            display_versions: Enum.take(versions, 5),
            changeset: changeset,
            daily_changes: daily_changes,
            limit_reached: false,
            css_framework: :tailwind_new
          })
      end
    end
  end

  defp maybe_update_line1(address_params, nil), do: address_params

  defp maybe_update_line1(address_params, name) when is_binary(name) do
    Map.put(address_params, "line1", name)
  end

  defp get_combined_versions(school) do
    address_versions =
      if school.address do
        PaperTrail.get_versions(school.address)
      else
        []
      end

    school_versions = PaperTrail.get_versions(school)

    (address_versions ++ school_versions)
    |> Enum.sort_by(& &1.inserted_at, :desc)
  end

  def rollback_school(conn, %{"slug" => school_slug, "version_id" => version_id}) do
    school = Locations.get_school_by_slug!(school_slug)

    # Check daily limit
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)

    if daily_changes >= 20 do
      conn
      |> put_flash(
        :error,
        "Das tägliche Limit von 20 Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
      )
      |> redirect(to: Routes.wiki_path(conn, :show_school, school_slug))
    else
      # Determine which model the version belongs to
      with {version_id_int, ""} <- Integer.parse(version_id),
           version when not is_nil(version) <-
             MehrSchulferien.Repo.get(PaperTrail.Version, version_id_int) do
        rollback_result =
          case version.item_type do
            "Location" when version.item_id == school.id ->
              # Rollback school name
              case Wiki.rollback_to_version(school, version_id, get_client_ip(conn)) do
                {:ok, %{model: updated_school, version: _version}} ->
                  # If there's an address, update its line1 to match the new school name
                  if updated_school.address do
                    address_changeset =
                      Address.changeset(updated_school.address, %{line1: updated_school.name})

                    case PaperTrail.update(address_changeset,
                           meta: %{ip_address: get_client_ip(conn)}
                         ) do
                      {:ok, %{model: _address, version: _addr_version}} ->
                        {:ok, updated_school}

                      {:error, _} ->
                        # Continue even if address update fails
                        {:ok, updated_school}
                    end
                  else
                    {:ok, updated_school}
                  end

                error ->
                  error
              end

            "Address" ->
              # Rollback address
              if school.address && version.item_id == school.address.id do
                Wiki.rollback_to_version(school.address, version_id, get_client_ip(conn))
              else
                {:error, :version_not_found}
              end

            _ ->
              {:error, :version_not_found}
          end

        case rollback_result do
          {:ok, _updated_model} ->
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
        _ ->
          conn
          |> put_flash(:error, "Ungültige Versions-ID.")
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
