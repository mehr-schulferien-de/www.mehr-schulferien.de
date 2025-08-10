defmodule MehrSchulferienWeb.WikiController do
  use MehrSchulferienWeb, :controller
  require Logger
  import Ecto.Query

  alias MehrSchulferien.{Locations, Maps, Wiki, Email, Mailer, Repo, Config}
  alias MehrSchulferien.Maps.Address
  alias MehrSchulferien.Geocoding.Nominatim

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
            if Application.get_env(:mehr_schulferien, :env) != :test do
              Logger.error("No coordinates found for #{name} at #{street}, #{zip_code} #{city}")
            end
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

  # Note: show_school is now handled by WikiSchoolShowLive

  def update_school(conn, %{"slug" => school_slug} = params) do
    school = Locations.get_school_by_slug!(school_slug)

    # Check daily limit
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)

    if daily_changes >= Config.daily_change_limit() do
      conn
      |> put_flash(
        :error,
        "Das tägliche Limit von #{Config.daily_change_limit()} Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
      )
      |> redirect(to: "/wiki/schools/#{school_slug}")
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

          # Send email notification if there were any changes
          if school_version || address_version do
            email_task = fn ->
              # Gather change information
              changes = gather_changes(school_version, address_version)

              Logger.info("Sending email notification for school update")
              Logger.info("School: #{inspect(updated_school.name)}")
              Logger.info("Changes: #{inspect(changes)}")

              # Get country slug for the email
              country_slug = get_country_slug_from_school(updated_school)

              result =
                Email.school_updated_notification(
                  updated_school,
                  updated_school.address,
                  changes,
                  country_slug
                )
                |> Mailer.deliver()

              Logger.info("Email send result: #{inspect(result)}")
            end

            # Run synchronously in test environment to avoid connection ownership issues
            if Application.get_env(:mehr_schulferien, :env) == :test do
              email_task.()
            else
              Task.start(email_task)
            end
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
          |> redirect(to: ~p"/ferien/#{country_slug}/schule/#{school_slug}")

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

    if daily_changes >= Config.daily_change_limit() do
      conn
      |> put_flash(
        :error,
        "Das tägliche Limit von #{Config.daily_change_limit()} Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
      )
      |> redirect(to: "/wiki/schools/#{school_slug}")
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
            |> redirect(to: ~p"/ferien/#{country_slug}/schule/#{school_slug}")

          {:error, _} ->
            conn
            |> put_flash(:error, "Fehler beim Zurückkehren zur ausgewählten Version.")
            |> redirect(to: "/wiki/schools/#{school_slug}")
        end
      else
        _ ->
          conn
          |> put_flash(:error, "Ungültige Versions-ID.")
          |> redirect(to: "/wiki/schools/#{school_slug}")
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
    case Locations.get_location(parent_id) do
      nil -> nil
      parent -> traverse_to_country(parent)
    end
  end

  defp traverse_to_country(_), do: nil

  defp gather_changes(school_version, address_version) do
    changes = %{}

    changes =
      if school_version do
        # Get the previous value for the school
        old_values = get_previous_values("Location", school_version.item_id, school_version)

        school_changes =
          case school_version.item_changes do
            %{name: new_name} ->
              old_name = Map.get(old_values, :name, "")
              %{"Schulname" => {old_name, new_name}}

            _ ->
              %{}
          end

        Map.merge(changes, school_changes)
      else
        changes
      end

    if address_version do
      # Get the previous values for the address
      old_values = get_previous_values("Address", address_version.item_id, address_version)

      address_changes =
        address_version.item_changes
        |> Enum.map(fn {field, new_value} ->
          field_str = to_string(field)
          field_atom = String.to_atom(field_str)
          old_value = Map.get(old_values, field_atom, "")
          {field_name(field_str), {old_value, new_value}}
        end)
        |> Enum.into(%{})

      Map.merge(changes, address_changes)
    else
      changes
    end
  end

  defp get_previous_values(item_type, item_id, current_version) do
    # Get all versions for this item
    versions =
      from(v in PaperTrail.Version,
        where: v.item_type == ^item_type and v.item_id == ^item_id,
        order_by: [asc: v.id]
      )
      |> Repo.all()

    # Find the index of the current version
    current_index = Enum.find_index(versions, fn v -> v.id == current_version.id end)

    if current_index && current_index > 0 do
      # Get all versions before the current one
      previous_versions = Enum.take(versions, current_index)

      # Reconstruct the state from all previous versions
      previous_versions
      |> Enum.reduce(%{}, fn version, acc ->
        changes = version.item_changes || %{}

        # Convert keys to atoms and merge
        atomized_changes =
          changes
          |> Enum.map(fn {k, v} ->
            {if(is_atom(k), do: k, else: String.to_atom(k)), v}
          end)
          |> Enum.into(%{})

        Map.merge(acc, atomized_changes)
      end)
    else
      # No previous version, return empty map
      %{}
    end
  end

  defp field_name("street"), do: "Straße"
  defp field_name("zip_code"), do: "PLZ"
  defp field_name("city"), do: "Stadt"
  defp field_name("email_address"), do: "E-Mail"
  defp field_name("phone_number"), do: "Telefon"
  defp field_name("homepage_url"), do: "Homepage"
  defp field_name("line1"), do: "Adresszeile 1"
  defp field_name(field), do: field

  defp gather_period_changes(version) do
    # Get the previous values for the period
    old_values = get_previous_values("Period", version.item_id, version)

    version.item_changes
    |> Enum.map(fn {field, new_value} ->
      field_str = to_string(field)
      field_atom = String.to_atom(field_str)
      old_value = Map.get(old_values, field_atom, "")
      {period_field_name(field_str), {old_value, new_value}}
    end)
    |> Enum.into(%{})
  end

  defp period_field_name("starts_on"), do: "Beginn"
  defp period_field_name("ends_on"), do: "Ende"
  defp period_field_name("location_id"), do: "Bundesland"
  defp period_field_name("holiday_or_vacation_type_id"), do: "Ferienart"
  defp period_field_name("memo"), do: "Notiz"
  defp period_field_name(field), do: field

  def delete_school(conn, %{"slug" => school_slug}) do
    school = Locations.get_school_by_slug!(school_slug)

    # Check daily limit
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)

    if daily_changes >= Config.daily_change_limit() do
      conn
      |> put_flash(
        :error,
        "Das tägliche Limit von #{Config.daily_change_limit()} Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
      )
      |> redirect(to: "/wiki/schools/#{school_slug}")
    else
      # Get the school with address preloaded for email
      school = Repo.preload(school, :address)

      # Get city for redirect after deletion
      city =
        if school.parent_location_id do
          Locations.get_location!(school.parent_location_id)
        else
          nil
        end

      # Get country slug for redirect after deletion
      country_slug = get_country_slug_from_school(school)

      case Locations.delete_school(school, deleted_by_user_id: nil) do
        {:ok, %{school: _deleted_school, periods: _deleted_periods}} ->
          # Increment daily change count
          Wiki.increment_daily_change_count(today)

          # Send email notification
          email_task = fn ->
            Logger.info("Sending email notification for school deletion")
            Logger.info("School: #{inspect(school.name)}")

            result =
              Email.school_deleted_notification(
                school,
                school.address,
                country_slug
              )
              |> Mailer.deliver()

            Logger.info("Email send result: #{inspect(result)}")
          end

          # Run synchronously in test environment to avoid connection ownership issues
          if Application.get_env(:mehr_schulferien, :env) == :test do
            email_task.()
          else
            Task.start(email_task)
          end

          # Redirect to city page if city exists, otherwise to country page
          redirect_path =
            if city && city.slug do
              ~p"/ferien/#{country_slug}/stadt/#{city.slug}"
            else
              ~p"/ferien/#{country_slug}"
            end

          conn
          |> put_flash(
            :info,
            "Die Schule \"#{school.name}\" wurde erfolgreich gelöscht."
          )
          |> redirect(to: redirect_path)

        {:error, reason} ->
          conn
          |> put_flash(:error, "Fehler beim Löschen der Schule: #{inspect(reason)}")
          |> redirect(to: "/wiki/schools/#{school_slug}")
      end
    end
  end

  # Period management functions
  def update_period(conn, %{"id" => period_id} = params) do
    period = MehrSchulferien.Periods.get_period!(period_id)

    # Check daily limit
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)

    if daily_changes >= Config.daily_change_limit() do
      conn
      |> put_flash(
        :error,
        "Das tägliche Limit von #{Config.daily_change_limit()} Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
      )
      |> redirect(to: ~p"/wiki/periods/#{period_id}/edit")
    else
      period_params = Map.get(params, "period", %{})
      changeset = MehrSchulferien.Periods.Period.changeset(period, period_params)

      case PaperTrail.update(changeset, meta: %{ip_address: get_client_ip(conn)}) do
        {:ok, %{model: updated_period, version: version}} ->
          # Increment daily change count if there was a version created
          if version do
            Wiki.increment_daily_change_count(today)

            # Send email notification
            email_task = fn ->
              Logger.info("Sending email notification for period update")
              changes = gather_period_changes(version)

              result =
                Email.period_updated_notification(updated_period, changes)
                |> Mailer.deliver()

              Logger.info("Email send result: #{inspect(result)}")
            end

            # Run synchronously in test environment to avoid connection ownership issues
            if Application.get_env(:mehr_schulferien, :env) == :test do
              email_task.()
            else
              Task.start(email_task)
            end
          end

          conn
          |> put_flash(:info, "Ferientermin wurde erfolgreich aktualisiert.")
          |> redirect(to: ~p"/wiki/periods")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Fehler beim Aktualisieren des Ferientermins.")
          |> redirect(to: ~p"/wiki/periods/#{period_id}/edit")
      end
    end
  end

  def delete_period(conn, %{"id" => period_id}) do
    period = MehrSchulferien.Periods.get_period!(period_id)

    # Check daily limit
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)

    if daily_changes >= Config.daily_change_limit() do
      conn
      |> put_flash(
        :error,
        "Das tägliche Limit von #{Config.daily_change_limit()} Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
      )
      |> redirect(to: ~p"/wiki/periods/#{period_id}/edit")
    else
      case MehrSchulferien.Periods.delete_period(period) do
        {:ok, _period} ->
          # Increment daily change count
          Wiki.increment_daily_change_count(today)

          # Send email notification
          email_task = fn ->
            Logger.info("Sending email notification for period deletion")

            result =
              Email.period_deleted_notification(period)
              |> Mailer.deliver()

            Logger.info("Email send result: #{inspect(result)}")
          end

          # Run synchronously in test environment to avoid connection ownership issues
          if Application.get_env(:mehr_schulferien, :env) == :test do
            email_task.()
          else
            Task.start(email_task)
          end

          conn
          |> put_flash(:info, "Ferientermin wurde erfolgreich gelöscht.")
          |> redirect(to: ~p"/wiki/periods")

        {:error, _} ->
          conn
          |> put_flash(:error, "Fehler beim Löschen des Ferientermins.")
          |> redirect(to: ~p"/wiki/periods/#{period_id}/edit")
      end
    end
  end

  def rollback_period(conn, %{"id" => period_id, "version_id" => version_id}) do
    period = MehrSchulferien.Periods.get_period!(period_id)

    # Check daily limit
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)

    if daily_changes >= Config.daily_change_limit() do
      conn
      |> put_flash(
        :error,
        "Das tägliche Limit von #{Config.daily_change_limit()} Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
      )
      |> redirect(to: ~p"/wiki/periods/#{period_id}/edit")
    else
      case Wiki.rollback_to_version(period, version_id, get_client_ip(conn)) do
        {:ok, _updated_period} ->
          # Increment daily change count
          Wiki.increment_daily_change_count(today)

          conn
          |> put_flash(:info, "Erfolgreich zur ausgewählten Version zurückgekehrt.")
          |> redirect(to: ~p"/wiki/periods/#{period_id}/edit")

        {:error, _} ->
          conn
          |> put_flash(:error, "Fehler beim Zurückkehren zur ausgewählten Version.")
          |> redirect(to: ~p"/wiki/periods/#{period_id}/edit")
      end
    end
  end
end
