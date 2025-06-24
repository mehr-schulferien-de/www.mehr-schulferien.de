defmodule MehrSchulferienWeb.WikiController do
  use MehrSchulferienWeb, :controller
  require Logger

  alias MehrSchulferien.{Locations, Maps, Wiki}
  alias MehrSchulferien.Maps.Address
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Geocoding.Nominatim

  def new_school(conn, _params) do
    {daily_changes, limit_reached} = get_daily_limit_info()

    # Create changeset for new school
    changeset =
      %Address{}
      |> Maps.change_address()
      |> Map.put(:data, %{name: "", street: "", zip_code: "", city: ""})

    render(conn, "new_school.html", %{
      changeset: changeset,
      daily_changes: daily_changes,
      limit_reached: limit_reached,
      css_framework: :tailwind_new
    })
  end

  def create_school(conn, params) do
    case check_daily_limit(conn) do
      {:error, _daily_changes} ->
        conn
        |> put_flash(
          :error,
          "Das tägliche Limit von 20 Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
        )
        |> redirect(to: "/wiki/schools/new")

      {:ok, daily_changes} ->
        # Extract school and address params
        school_name = Map.get(params, "name", "")
        address_params = Map.get(params, "address", %{})
        zip_code = Map.get(address_params, "zip_code", "")

        # Validate zip code and get city
        with {:ok, city} <- validate_and_get_city_from_zip(zip_code),
             {:ok, school} <- create_school_with_address(school_name, address_params, city, conn) do
          # Increment daily change count
          Wiki.increment_daily_change_count(Date.utc_today())

          # Get country slug for redirect
          country_slug = get_country_slug_from_school(school)

          conn
          |> put_flash(:info, "Schule wurde erfolgreich angelegt. Danke für Ihre Hilfe!")
          |> redirect(to: Routes.school_path(conn, :show, country_slug || "d", school.slug))
        else
          {:error, :invalid_zip_code} ->
            render_form_with_error(
              conn,
              "new_school.html",
              school_name,
              address_params,
              :invalid_zip_code,
              daily_changes
            )

          {:error, :invalid_address} ->
            render_form_with_error(
              conn,
              "new_school.html",
              school_name,
              address_params,
              :invalid_address,
              daily_changes
            )

          {:error, changeset} ->
            render_form_with_error(
              conn,
              "new_school.html",
              school_name,
              address_params,
              {:changeset, changeset},
              daily_changes
            )
        end
    end
  end

  defp validate_and_get_city_from_zip(zip_code) when is_binary(zip_code) and zip_code != "" do
    try do
      zip_code_record = Maps.get_zip_code_by_value!(zip_code)

      case zip_code_record.locations do
        [city | _] -> {:ok, city}
        [] -> {:error, :invalid_zip_code}
      end
    rescue
      Ecto.NoResultsError -> {:error, :invalid_zip_code}
    end
  end

  defp validate_and_get_city_from_zip(_), do: {:error, :invalid_zip_code}

  defp create_school_with_address(school_name, address_params, city, conn) do
    # Generate slug with zip code prefix to match existing school slug pattern
    zip_code = Map.get(address_params, "zip_code", "")
    base_slug = Slugger.slugify_downcase(school_name)
    school_slug = "#{zip_code}-#{base_slug}"

    # Create school location
    school_attrs = %{
      name: school_name,
      slug: school_slug,
      is_school: true,
      parent_location_id: city.id
    }

    school_changeset = Location.changeset(%Location{}, school_attrs)

    # First check if we can get coordinates for this address
    coords_result =
      get_coordinates_with_fallback(
        school_name,
        address_params["street"],
        zip_code,
        address_params["city"] || city.name
      )

    case coords_result do
      {:ok, {lon, lat}} ->
        # Coordinates found, proceed with school creation
        case PaperTrail.insert(school_changeset, meta: %{ip_address: get_client_ip(conn)}) do
          {:ok, %{model: school, version: _}} ->
            # Create address for the school
            address_attrs =
              address_params
              |> Map.put("school_location_id", school.id)
              |> Map.put("line1", school_name)
              |> Map.put("lon", lon)
              |> Map.put("lat", lat)

            address_changeset = Address.changeset(%Address{}, address_attrs)

            case PaperTrail.insert(address_changeset, meta: %{ip_address: get_client_ip(conn)}) do
              {:ok, %{model: _address, version: _}} ->
                # Reload school with address and parent location chain
                school =
                  Locations.get_location!(school.id)
                  |> MehrSchulferien.Repo.preload([:address, :parent_location])

                {:ok, school}

              {:error, changeset} ->
                # Delete the school if address creation fails
                PaperTrail.delete(school, meta: %{ip_address: get_client_ip(conn)})
                {:error, changeset}
            end

          {:error, changeset} ->
            {:error, changeset}
        end

      {:error, :no_coordinates} ->
        # No coordinates found - return invalid address error
        {:error, :invalid_address}
    end
  end

  defp get_coordinates_with_fallback(name, street, zip_code, city) do
    # First try Nominatim with full address
    case Nominatim.geocode_address(street, zip_code, city) do
      {:ok, {lon, lat}} ->
        Logger.info("Coordinates found via Nominatim for #{name}: #{lon}, #{lat}")
        {:ok, {lon, lat}}

      {:error, reason} ->
        Logger.warning(
          "Nominatim failed for #{name}: #{inspect(reason)}, trying zip_code_mappings"
        )

        # Fallback to zip_code_mappings
        case get_coordinates_from_zip_mappings(zip_code) do
          {lon, lat} when not is_nil(lon) and not is_nil(lat) ->
            Logger.info("Coordinates found via zip_code_mappings for #{name}: #{lon}, #{lat}")
            {:ok, {lon, lat}}

          _ ->
            Logger.error("No coordinates found for #{name} at #{street}, #{zip_code} #{city}")
            {:error, :no_coordinates}
        end
    end
  end

  defp get_coordinates_from_zip_mappings(zip_code) when is_binary(zip_code) and zip_code != "" do
    import Ecto.Query

    zip_query =
      from zm in MehrSchulferien.Maps.ZipCodeMapping,
        join: z in MehrSchulferien.Maps.ZipCode,
        on: zm.zip_code_id == z.id,
        where: z.value == ^zip_code,
        select: {zm.lon, zm.lat},
        limit: 1

    case MehrSchulferien.Repo.one(zip_query) do
      {lon, lat} when not is_nil(lon) and not is_nil(lat) -> {lon, lat}
      _ -> {nil, nil}
    end
  end

  defp get_coordinates_from_zip_mappings(_), do: {nil, nil}

  defp get_coordinates_for_update(school, street, zip_code, city)
       when is_binary(zip_code) and zip_code != "" do
    # Use the same logic as for new schools
    case get_coordinates_with_fallback(school.name, street, zip_code, city) do
      {:ok, {lon, lat}} -> {lon, lat}
      {:error, :no_coordinates} -> {nil, nil}
    end
  end

  defp get_coordinates_for_update(_school, _street, _zip_code, _city), do: {nil, nil}

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

              # Check if location fields have changed
              location_changed =
                address_params["street"] != old_address.street ||
                  address_params["zip_code"] != old_address.zip_code ||
                  address_params["city"] != old_address.city

              # Update coordinates if location changed
              address_params =
                if location_changed do
                  street = address_params["street"] || old_address.street
                  zip_code = address_params["zip_code"] || old_address.zip_code
                  city = address_params["city"] || old_address.city

                  # Try to get updated coordinates
                  {lon, lat} = get_coordinates_for_update(updated_school, street, zip_code, city)

                  # Only update coordinates if we found new ones
                  if lon && lat do
                    address_params
                    |> Map.put("lon", lon)
                    |> Map.put("lat", lat)
                  else
                    # For updates, keep existing coordinates if we can't find new ones
                    # This prevents losing valid coordinates due to temporary API failures
                    address_params
                  end
                else
                  address_params
                end

              changeset = Address.changeset(old_address, address_params)

              case changeset.changes do
                changes when map_size(changes) == 0 ->
                  {:ok, %{model: old_address, version: nil}}

                _ ->
                  PaperTrail.update(changeset, meta: %{ip_address: get_client_ip(conn)})
              end
            else
              # Create new address
              street = address_params["street"] || ""
              zip_code = address_params["zip_code"] || ""
              city = address_params["city"] || ""

              # Check if we can get coordinates
              coords_result =
                get_coordinates_with_fallback(updated_school.name, street, zip_code, city)

              case coords_result do
                {:ok, {lon, lat}} ->
                  # Coordinates found, create address
                  address_params =
                    address_params
                    |> Map.put("lon", lon)
                    |> Map.put("lat", lat)

                  changeset = Address.changeset(%Address{}, address_params)
                  PaperTrail.insert(changeset, meta: %{ip_address: get_client_ip(conn)})

                {:error, :no_coordinates} ->
                  # No coordinates found - don't create address
                  {:error, :invalid_address}
              end
            end

          error ->
            error
        end

      case {school_result, address_result} do
        {{:ok, %{model: _updated_school, version: school_version}},
         {:ok, %{model: _address, version: address_version}}} ->
          # Send email notification if there were changes
          if school_version || address_version do
            # Increment daily change count
            Wiki.increment_daily_change_count(today)
          end

          # Reload school to get updated address
          updated_school = Locations.get_school_by_slug!(school_slug)

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

        {_, {:error, :invalid_address}} ->
          # Address update failed due to no coordinates
          versions = get_combined_versions(school)

          # Create a changeset with the address error
          changeset =
            if school.address do
              Maps.change_address(school.address)
            else
              Maps.change_address(%Address{school_location_id: school.id})
            end

          changeset = %{
            changeset
            | errors: [
                street:
                  {"Die Adresse konnte nicht georeferenziert werden. Bitte überprüfen Sie die Eingaben.",
                   []}
              ],
              valid?: false,
              action: :update
          }

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
    # Traverse up the hierarchy to find the country
    # Be flexible about hierarchy levels since test data might skip intermediate levels
    location = school

    # Keep going up until we find a country or run out of parents
    location = traverse_to_country(location)

    case location do
      %{slug: slug, is_country: true} -> slug
      # Default to Germany
      _ -> "d"
    end
  end

  defp traverse_to_country(%{is_country: true} = location), do: location
  defp traverse_to_country(%{parent_location_id: nil}), do: nil

  defp traverse_to_country(%{parent_location_id: parent_id}) do
    parent = Locations.get_location!(parent_id)
    traverse_to_country(parent)
  end

  defp traverse_to_country(_), do: nil

  defp get_daily_limit_info do
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)
    limit_reached = daily_changes >= 20
    {daily_changes, limit_reached}
  end

  defp check_daily_limit(_conn) do
    {daily_changes, limit_reached} = get_daily_limit_info()

    if limit_reached do
      {:error, daily_changes}
    else
      {:ok, daily_changes}
    end
  end

  defp render_form_with_error(
         conn,
         template,
         _school_name,
         address_params,
         error_type,
         daily_changes
       ) do
    changeset =
      case error_type do
        :invalid_zip_code ->
          changeset = Address.changeset(%Address{}, address_params)
          # Add the zip code error
          %{
            changeset
            | errors: [zip_code: {"Postleitzahl wurde nicht gefunden oder ist ungültig", []}],
              valid?: false,
              action: :insert
          }

        :invalid_address ->
          changeset = Address.changeset(%Address{}, address_params)
          # Add a general address error
          %{
            changeset
            | errors: [
                street:
                  {"Die Adresse konnte nicht georeferenziert werden. Bitte überprüfen Sie die Eingaben.",
                   []}
              ],
              valid?: false,
              action: :insert
          }

        {:changeset, changeset} ->
          changeset
      end

    render(conn, template, %{
      changeset: changeset,
      daily_changes: daily_changes,
      limit_reached: false,
      css_framework: :tailwind_new,
      school: Map.get(conn.assigns, :school)
    })
  end
end
