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
            
            # Reload data
            updated_school = Locations.get_school_by_slug!(school.slug)
            versions = get_combined_versions(updated_school)
            daily_changes = Wiki.get_daily_change_count(today)
            limit_reached = daily_changes >= Config.daily_change_limit()
            
            # Send email notification
            Task.start(fn ->
              try do
                # Reload school with all associations needed for email
                updated_school_with_associations = 
                  Locations.get_location!(updated_school.id)
                  |> Repo.preload([:address, :parent_location])
                
                # Gather change information
                changes = gather_changes(school_version, address_version)
                
                Logger.info("Sending email notification for school update")
                Logger.info("School: #{inspect(updated_school_with_associations.name)}")
                Logger.info("Changes: #{inspect(changes)}")
                
                # Get country slug for the email
                country_slug = get_country_slug_from_school(updated_school_with_associations)
                Logger.info("Country slug: #{inspect(country_slug)}")
                
                result =
                  Email.school_updated_notification(
                    updated_school_with_associations,
                    updated_school_with_associations.address,
                    changes,
                    country_slug
                  )
                  |> Mailer.deliver!()
                
                Logger.info("Email sent successfully: #{inspect(result)}")
              rescue
                error ->
                  Logger.error("Failed to send school update email: #{inspect(error)}")
                  Logger.error(Exception.format(:error, error, __STACKTRACE__))
              end
            end)
            
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
    
    case version.item_type do
      "Location" ->
        if Map.has_key?(changes, :name) do
          old_name = get_old_value(version, :name, "")
          new_name = changes.name
          "Schulname: \"#{old_name}\" → \"#{new_name}\""
        else
          "Schulinformationen geändert"
        end
        
      "Address" ->
        change_descriptions = 
          Enum.map(changes, fn {field, new_value} ->
            old_value = get_old_value(version, field, "")
            
            case field do
              :street -> "Straße: \"#{old_value}\" → \"#{new_value}\""
              :zip_code -> "PLZ: \"#{old_value}\" → \"#{new_value}\""
              :city -> "Stadt: \"#{old_value}\" → \"#{new_value}\""
              :email_address -> "E-Mail: \"#{old_value}\" → \"#{new_value}\""
              :phone_number -> "Telefon: \"#{old_value}\" → \"#{new_value}\""
              :homepage_url -> "Homepage: \"#{old_value}\" → \"#{new_value}\""
              :wikipedia_url -> "Wikipedia: \"#{old_value}\" → \"#{new_value}\""
              _ -> nil
            end
          end)
          |> Enum.reject(&is_nil/1)
          
        if Enum.empty?(change_descriptions) do
          "Adressinformationen geändert"
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
        versions = 
          PaperTrail.get_versions(%{item_type: version.item_type, item_id: version.item_id})
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
    versions =
      PaperTrail.get_versions(%{item_type: item_type, item_id: item_id})
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
          # Restore to the state before this version using old_values
          old_values = version.old_values || %{}
          changeset = Ecto.Changeset.change(model, old_values)
          PaperTrail.update(changeset, meta: %{ip_address: nil})
        else
          {:error, :model_not_found}
        end
        
      _ ->
        {:error, :cannot_restore_event}
    end
  end
end
