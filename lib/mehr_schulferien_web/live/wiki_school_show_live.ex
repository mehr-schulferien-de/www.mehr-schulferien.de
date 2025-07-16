defmodule MehrSchulferienWeb.WikiSchoolShowLive do
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferien.{Locations, Maps, Wiki, Email, Mailer, Periods, Config, Repo}
  alias MehrSchulferien.Maps.Address
  alias PaperTrail
  require Logger

  @impl true
  def mount(%{"slug" => school_slug}, _session, socket) do
    school = Locations.get_school_by_slug!(school_slug)

    # Get combined version history for both school and address
    versions = get_combined_versions(school)

    # Get daily change count
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)
    limit_reached = daily_changes >= Config.daily_change_limit()

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

    # Get bewegliche Ferientage for the school
    bewegliche_ferientage = Periods.list_bewegliche_ferientage_for_school(school.id)

    {:ok,
     assign(socket,
       school: school,
       versions: versions,
       display_versions: Enum.take(versions, 5),
       changeset: changeset,
       daily_changes: daily_changes,
       limit_reached: limit_reached,
       bewegliche_ferientage: bewegliche_ferientage
     )}
  end

  @impl true
  def handle_event("update_school", %{"address" => address_params, "name" => name}, socket) do
    if socket.assigns.limit_reached do
      {:noreply,
       put_flash(
         socket,
         :error,
         "Das tägliche Limit von #{Config.daily_change_limit()} Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
       )}
    else
      school = socket.assigns.school
      today = Date.utc_today()
      
      # Update school name if changed
      school_result =
        if name != school.name do
          location_changeset = MehrSchulferien.Locations.Location.changeset(school, %{name: name})
          # Note: We can't get IP address in LiveView easily, so using nil
          PaperTrail.update(location_changeset, meta: %{ip_address: nil})
        else
          {:ok, %{model: school, version: nil}}
        end

      # Handle address update/creation
      address_result =
        case school_result do
          {:ok, %{model: updated_school, version: _school_version}} ->
            address_params =
              address_params
              |> Map.put("school_location_id", updated_school.id)
              |> Map.put("line1", name)

            if updated_school.address do
              # Update existing address
              changeset = Address.changeset(updated_school.address, address_params)
              
              case changeset.changes do
                changes when map_size(changes) == 0 ->
                  {:ok, %{model: updated_school.address, version: nil}}
                _ ->
                  PaperTrail.update(changeset, meta: %{ip_address: nil})
              end
            else
              # Create new address
              changeset = Address.changeset(%Address{}, address_params)
              PaperTrail.insert(changeset, meta: %{ip_address: nil})
            end
            
          error ->
            error
        end

      case {school_result, address_result} do
        {{:ok, %{model: _updated_school, version: school_version}},
         {:ok, %{model: _address, version: address_version}}} ->
          
          if school_version || address_version do
            Wiki.increment_daily_change_count(today)
            
            Logger.info("=== SCHOOL UPDATE EMAIL DEBUG START ===")
            Logger.info("Changes detected - school_version: #{inspect(school_version != nil)}, address_version: #{inspect(address_version != nil)}")
            
            # Reload data
            updated_school = Locations.get_school_by_slug!(school.slug)
            versions = get_combined_versions(updated_school)
            daily_changes = Wiki.get_daily_change_count(today)
            limit_reached = daily_changes >= Config.daily_change_limit()
            
            # Send email notification
            email_task = Task.async(fn ->
              try do
                Logger.info("Email task started")
                
                # Reload school with all associations needed for email
                updated_school_with_associations = 
                  Locations.get_location!(updated_school.id)
                  |> Repo.preload([:address, :parent_location])
                
                Logger.info("School loaded with associations: id=#{updated_school_with_associations.id}, has_address=#{updated_school_with_associations.address != nil}")
                
                # Gather change information
                changes = gather_changes(school_version, address_version)
                
                Logger.info("Changes gathered: #{inspect(changes)}")
                
                # Get country slug for the email
                country_slug = get_country_slug_from_school(updated_school_with_associations)
                Logger.info("Country slug: #{inspect(country_slug)}")
                
                # Build email
                email = Email.school_updated_notification(
                  updated_school_with_associations,
                  updated_school_with_associations.address,
                  changes,
                  country_slug
                )
                
                Logger.info("Email built: to=#{inspect(email.to)}, subject=#{inspect(email.subject)}")
                
                # Send email
                result = Mailer.deliver!(email)
                
                Logger.info("Email sent successfully: #{inspect(result)}")
                {:ok, result}
              rescue
                error ->
                  Logger.error("Failed to send school update email: #{inspect(error)}")
                  Logger.error(Exception.format(:error, error, __STACKTRACE__))
                  {:error, error}
              end
            end)
            
            # Wait a bit to see if the task completes
            case Task.yield(email_task, 5000) || Task.shutdown(email_task, :brutal_kill) do
              {:ok, {:ok, result}} ->
                Logger.info("Email task completed successfully: #{inspect(result)}")
              {:ok, {:error, error}} ->
                Logger.error("Email task failed: #{inspect(error)}")
              nil ->
                Logger.warning("Email task timed out after 5 seconds")
              {:exit, reason} ->
                Logger.error("Email task crashed: #{inspect(reason)}")
            end
            
            Logger.info("=== SCHOOL UPDATE EMAIL DEBUG END ===")
            
            # Update changeset
            changeset =
              if updated_school.address do
                address_changeset = Maps.change_address(updated_school.address)
                %{address_changeset | data: Map.merge(address_changeset.data, %{name: updated_school.name})}
              else
                address_changeset = Maps.change_address(%Address{school_location_id: updated_school.id})
                %{address_changeset | data: Map.merge(address_changeset.data, %{name: updated_school.name})}
              end
            
            {:noreply,
             socket
             |> put_flash(:info, "Änderungen wurden erfolgreich gespeichert.")
             |> assign(
               school: updated_school,
               versions: versions,
               display_versions: Enum.take(versions, 5),
               changeset: changeset,
               daily_changes: daily_changes,
               limit_reached: limit_reached
             )}
          else
            {:noreply, put_flash(socket, :info, "Keine Änderungen vorgenommen.")}
          end
          
        {{:error, _}, _} ->
          {:noreply, put_flash(socket, :error, "Fehler beim Aktualisieren des Schulnamens.")}
          
        {_, {:error, :invalid_address}} ->
          {:noreply, put_flash(socket, :error, "Ungültige Adresse. Bitte überprüfen Sie die Eingaben.")}
          
        {_, {:error, _}} ->
          {:noreply, put_flash(socket, :error, "Fehler beim Aktualisieren der Adresse.")}
      end
    end
  end

  @impl true
  def handle_event("add_beweglicher_ferientag", %{"ferientag" => params}, socket) do
    if socket.assigns.limit_reached do
      {:noreply,
       put_flash(socket, :error, "Tageslimit erreicht. Keine weiteren Änderungen möglich.")}
    else
      school = socket.assigns.school
      date = Date.from_iso8601!(params["date"])
      memo = params["memo"]
      today = Date.utc_today()

      cond do
        Date.compare(date, today) == :lt ->
          {:noreply,
           put_flash(
             socket,
             :error,
             "Bewegliche Ferientage können nur für zukünftige Daten angelegt werden."
           )}

        has_beweglicher_ferientag_on_date?(socket.assigns.bewegliche_ferientage, date) ->
          {:noreply,
           put_flash(
             socket,
             :error,
             "Für dieses Datum existiert bereits ein beweglicher Ferientag."
           )}

        true ->
          case Periods.create_beweglicher_ferientag_for_school(school.id, date, memo) do
            {:ok, period} ->
              # Send email notification
              Email.beweglicher_ferientag_created_notification(period, school)
              |> Mailer.deliver!()

              # Reload bewegliche Ferientage
              bewegliche_ferientage = Periods.list_bewegliche_ferientage_for_school(school.id)

              {:noreply,
               socket
               |> put_flash(:info, "Beweglicher Ferientag wurde erfolgreich hinzugefügt.")
               |> assign(bewegliche_ferientage: bewegliche_ferientage)}

            {:error, error} when is_binary(error) ->
              {:noreply, put_flash(socket, :error, error)}

            {:error, _changeset} ->
              {:noreply,
               put_flash(socket, :error, "Fehler beim Hinzufügen des beweglichen Ferientags.")}
          end
      end
    end
  end

  @impl true
  def handle_event("delete_beweglicher_ferientag", %{"id" => id}, socket) do
    if socket.assigns.limit_reached do
      {:noreply,
       put_flash(socket, :error, "Tageslimit erreicht. Keine weiteren Änderungen möglich.")}
    else
      period = Periods.get_period!(id)
      school = socket.assigns.school

      case Periods.delete_period(period) do
        {:ok, deleted_period} ->
          # Send email notification
          Email.beweglicher_ferientag_deleted_notification(deleted_period, school)
          |> Mailer.deliver!()

          # Clear cache
          Periods.clear_periods_cache_for_locations([school.id])

          # Reload bewegliche Ferientage
          bewegliche_ferientage = Periods.list_bewegliche_ferientage_for_school(school.id)

          {:noreply,
           socket
           |> put_flash(:info, "Beweglicher Ferientag wurde gelöscht.")
           |> assign(bewegliche_ferientage: bewegliche_ferientage)}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Fehler beim Löschen des beweglichen Ferientags.")}
      end
    end
  end

  @impl true
  def handle_event("rollback_version", %{"id" => version_id}, socket) do
    if socket.assigns.limit_reached do
      {:noreply,
       put_flash(
         socket,
         :error,
         "Das tägliche Limit von #{Config.daily_change_limit()} Änderungen wurde erreicht."
       )}
    else
      version = PaperTrail.get_version(version_id)
      
      case restore_version(version) do
        {:ok, _restored} ->
          today = Date.utc_today()
          Wiki.increment_daily_change_count(today)
          
          # Reload school and data
          school = Locations.get_school_by_slug!(socket.assigns.school.slug)
          versions = get_combined_versions(school)
          daily_changes = Wiki.get_daily_change_count(today)
          limit_reached = daily_changes >= Config.daily_change_limit()
          
          # Update changeset
          changeset =
            if school.address do
              address_changeset = Maps.change_address(school.address)
              %{address_changeset | data: Map.merge(address_changeset.data, %{name: school.name})}
            else
              address_changeset = Maps.change_address(%Address{school_location_id: school.id})
              %{address_changeset | data: Map.merge(address_changeset.data, %{name: school.name})}
            end
          
          {:noreply,
           socket
           |> put_flash(:info, "Erfolgreich zur ausgewählten Version zurückgekehrt.")
           |> assign(
             school: school,
             versions: versions,
             display_versions: Enum.take(versions, 5),
             changeset: changeset,
             daily_changes: daily_changes,
             limit_reached: limit_reached
           )}
           
        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Fehler beim Zurückkehren zur ausgewählten Version.")}
      end
    end
  end

  defp get_combined_versions(school) do
    school_versions = PaperTrail.get_versions(school)

    address_versions =
      if school.address do
        PaperTrail.get_versions(school.address)
      else
        []
      end

    (school_versions ++ address_versions)
    |> Enum.sort_by(& &1.inserted_at, {:desc, NaiveDateTime})
  end

  defp format_version_date(version) do
    version.inserted_at
    |> Calendar.strftime("%d.%m.%Y um %H:%M Uhr")
  end

  defp format_originator(%{originator: originator}) when not is_nil(originator) do
    originator
  end

  defp format_originator(_), do: "Unbekannt"

  defp version_summary(version, _all_versions) do
    # Get detailed changes for this version
    changes = version.item_changes || %{}
    
    # Debug log
    if map_size(changes) > 0 do
      Logger.debug("Version #{version.id} changes: #{inspect(changes)}")
    end
    
    case version.item_type do
      "Location" ->
        # Check for both string and atom keys
        if Map.has_key?(changes, :name) or Map.has_key?(changes, "name") do
          new_name = changes[:name] || changes["name"]
          old_name = get_old_value(version, :name, "[nicht verfügbar]")
          if old_name == "[nicht verfügbar]" do
            "Schulname geändert zu: \"#{new_name}\""
          else
            "Schulname: \"#{old_name}\" → \"#{new_name}\""
          end
        else
          "Schulinformationen geändert"
        end
        
      "Address" ->
        change_descriptions = 
          Enum.map(changes, fn {field, new_value} ->
            # Handle both string and atom keys
            field_name = cond do
              field == :street or field == "street" -> :street
              field == :zip_code or field == "zip_code" -> :zip_code
              field == :city or field == "city" -> :city
              field == :email_address or field == "email_address" -> :email_address
              field == :phone_number or field == "phone_number" -> :phone_number
              field == :homepage_url or field == "homepage_url" -> :homepage_url
              field == :wikipedia_url or field == "wikipedia_url" -> :wikipedia_url
              true -> nil
            end
            
            case field_name do
              :street -> 
                old_value = get_old_value(version, field, nil)
                if old_value do
                  "Straße: \"#{old_value}\" → \"#{new_value}\""
                else
                  "Straße: #{if new_value == "" or is_nil(new_value), do: "gelöscht", else: "\"#{new_value}\""}"
                end
                
              :zip_code -> 
                old_value = get_old_value(version, field, nil)
                if old_value do
                  "PLZ: \"#{old_value}\" → \"#{new_value}\""
                else
                  "PLZ: #{if new_value == "" or is_nil(new_value), do: "gelöscht", else: "\"#{new_value}\""}"
                end
                
              :city -> 
                old_value = get_old_value(version, field, nil)
                if old_value do
                  "Stadt: \"#{old_value}\" → \"#{new_value}\""
                else
                  "Stadt: #{if new_value == "" or is_nil(new_value), do: "gelöscht", else: "\"#{new_value}\""}"
                end
                
              :email_address -> 
                old_value = get_old_value(version, field, nil)
                if old_value do
                  "E-Mail: \"#{old_value}\" → \"#{new_value}\""
                else
                  "E-Mail: #{if new_value == "" or is_nil(new_value), do: "gelöscht", else: "\"#{new_value}\""}"
                end
                
              :phone_number -> 
                old_value = get_old_value(version, field, nil)
                if old_value do
                  "Telefon: \"#{old_value}\" → \"#{new_value}\""
                else
                  "Telefon: #{if new_value == "" or is_nil(new_value), do: "gelöscht", else: "\"#{new_value}\""}"
                end
                
              :homepage_url -> 
                old_value = get_old_value(version, field, nil)
                if old_value do
                  "Homepage: \"#{old_value}\" → \"#{new_value}\""
                else
                  "Homepage: #{if new_value == "" or is_nil(new_value), do: "gelöscht", else: "\"#{new_value}\""}"
                end
                
              :wikipedia_url -> 
                old_value = get_old_value(version, field, nil)
                if old_value do
                  "Wikipedia: \"#{old_value}\" → \"#{new_value}\""
                else
                  "Wikipedia: #{if new_value == "" or is_nil(new_value), do: "gelöscht", else: "\"#{new_value}\""}"
                end
                
              _ -> nil
            end
          end)
          |> Enum.reject(&is_nil/1)
          
        if Enum.empty?(change_descriptions) do
          # Show what fields were changed even if we don't have the old values
          if map_size(changes) > 0 do
            changed_fields = 
              changes
              |> Map.keys()
              |> Enum.map(fn field ->
                cond do
                  field in [:street, "street"] -> "Straße"
                  field in [:zip_code, "zip_code"] -> "PLZ"
                  field in [:city, "city"] -> "Stadt"
                  field in [:email_address, "email_address"] -> "E-Mail"
                  field in [:phone_number, "phone_number"] -> "Telefon"
                  field in [:homepage_url, "homepage_url"] -> "Homepage"
                  field in [:wikipedia_url, "wikipedia_url"] -> "Wikipedia"
                  field in [:line1, "line1"] -> nil  # Skip internal fields
                  field in [:school_location_id, "school_location_id"] -> nil
                  field in [:lon, "lon"] -> nil
                  field in [:lat, "lat"] -> nil
                  field in [:school_type, "school_type"] -> nil  # Skip null fields
                  true -> to_string(field)
                end
              end)
              |> Enum.reject(&is_nil/1)
              
            if length(changed_fields) > 0 do
              "Geänderte Felder: #{Enum.join(changed_fields, ", ")}"
            else
              "Adressinformationen geändert"
            end
          else
            "Adressinformationen geändert"
          end
        else
          Enum.join(change_descriptions, ", ")
        end
        
      _ -> 
        "Änderung"
    end
  end
  
  defp get_old_value(version, field, default) do
    # Try to get old value from paper_trail's old_values
    case version do
      %{old_values: old_values} when is_map(old_values) ->
        Map.get(old_values, field, default)
      _ ->
        # If no old_values, try to get from previous version
        # Get the model to pass to PaperTrail
        model = 
          case version.item_type do
            "Location" -> %MehrSchulferien.Locations.Location{id: version.item_id}
            "Address" -> %MehrSchulferien.Maps.Address{id: version.item_id}
            _ -> nil
          end
          
        versions = 
          if model do
            PaperTrail.get_versions(model)
          else
            []
          end
          |> Enum.filter(&(&1.id < version.id))
          |> Enum.sort_by(& &1.id, :desc)
          
        case versions do
          [prev_version | _] ->
            case prev_version.item_changes do
              %{^field => value} -> value
              _ -> default
            end
          [] ->
            default
        end
    end
  end

  defp has_beweglicher_ferientag_on_date?(ferientage, date) do
    Enum.any?(ferientage, fn ft -> Date.compare(ft.starts_on, date) == :eq end)
  end

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
      # Get the previous value for the address
      old_values = get_previous_values("Address", address_version.item_id, address_version)

      address_changes =
        Enum.reduce(address_version.item_changes, %{}, fn {field, new_value}, acc ->
          field_name =
            case field do
              :street -> "Straße"
              :zip_code -> "PLZ"
              :city -> "Stadt"
              :email_address -> "E-Mail"
              :phone_number -> "Telefon"
              :homepage_url -> "Homepage"
              :wikipedia_url -> "Wikipedia"
              _ -> nil
            end

          if field_name do
            old_value = Map.get(old_values, field, "")
            Map.put(acc, field_name, {old_value, new_value})
          else
            acc
          end
        end)

      Map.merge(changes, address_changes)
    else
      changes
    end
  end

  defp get_previous_values(item_type, item_id, current_version) do
    # Create proper struct for PaperTrail
    model = 
      case item_type do
        "Location" -> %MehrSchulferien.Locations.Location{id: item_id}
        "Address" -> %MehrSchulferien.Maps.Address{id: item_id}
        _ -> nil
      end
    
    versions =
      if model do
        PaperTrail.get_versions(model)
      else
        []
      end
      |> Enum.filter(&(&1.id < current_version.id))
      |> Enum.sort_by(& &1.id, :desc)

    case versions do
      [previous_version | _] ->
        # Get values from the previous version, handling old_values if present
        case previous_version do
          %{old_values: old_values} when is_map(old_values) ->
            old_values

          _ ->
            # If no old_values, reconstruct from item_changes
            previous_version.item_changes || %{}
        end

      [] ->
        # No previous version, so all fields were empty/nil
        %{}
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

  defp traverse_to_country(%{parent_location: %{is_country: true} = parent})
       when not is_nil(parent) do
    parent
  end

  defp traverse_to_country(%{parent_location: parent}) when not is_nil(parent) do
    parent = Locations.get_location!(parent.id) |> Repo.preload(:parent_location)
    traverse_to_country(parent)
  end

  defp traverse_to_country(_), do: nil
  
  defp restore_version(nil), do: {:error, :version_not_found}
  
  defp restore_version(version) do
    case version.event do
      "update" ->
        # Get the model
        model = 
          case version.item_type do
            "Location" -> Locations.get_location!(version.item_id)
            "Address" -> Maps.get_address!(version.item_id)
            _ -> nil
          end
          
        if model do
          # If we have old_values, restore to the state before this version
          # If not, we need to reconstruct the state from all versions
          restore_values = 
            if version.old_values && map_size(version.old_values) > 0 do
              version.old_values
            else
              # Get all versions up to but not including this one
              all_versions = 
                case version.item_type do
                  "Location" -> 
                    PaperTrail.get_versions(%MehrSchulferien.Locations.Location{id: version.item_id})
                  "Address" -> 
                    PaperTrail.get_versions(%MehrSchulferien.Maps.Address{id: version.item_id})
                  _ -> 
                    []
                end
                
              # Find the previous version to restore to
              previous_versions = 
                all_versions
                |> Enum.filter(&(&1.id < version.id))
                |> Enum.sort_by(& &1.id, :desc)
                
              case previous_versions do
                [prev_version | _] ->
                  # Use the changes from the previous version as our restore point
                  prev_version.item_changes || %{}
                [] ->
                  # This was the first change, so restore to empty/default values
                  %{}
              end
            end
            
          changeset = Ecto.Changeset.change(model, restore_values)
          PaperTrail.update(changeset, meta: %{ip_address: nil})
        else
          {:error, :model_not_found}
        end
        
      "insert" ->
        # Can't restore an insert event - would need to delete the record
        {:error, :cannot_restore_insert}
        
      _ ->
        {:error, :cannot_restore_event}
    end
  end
end
