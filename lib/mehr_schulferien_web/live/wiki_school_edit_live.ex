defmodule MehrSchulferienWeb.WikiSchoolEditLive do
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferien.{
    Locations,
    Maps,
    Wiki,
    Email,
    Mailer,
    Config,
    Repo,
    SearchEngineAPI
  }

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

    # Check if SERPAPI is available
    api_key_available = match?({:ok, _}, SearchEngineAPI.get_api_key())

    {:ok,
     assign(socket,
       school: school,
       versions: versions,
       display_versions: Enum.take(versions, 5),
       changeset: changeset,
       daily_changes: daily_changes,
       limit_reached: limit_reached,
       enrichment_loading: false,
       enrichment_data: nil,
       enrichment_error: nil,
       api_key_available: api_key_available
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

                # Get country slug for the email
                country_slug = get_country_slug_from_school(updated_school_with_associations)

                # Build and send email
                Email.school_updated_notification(
                  updated_school_with_associations,
                  updated_school_with_associations.address,
                  changes,
                  country_slug
                )
                |> Mailer.deliver!()
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

                %{
                  address_changeset
                  | data: Map.merge(address_changeset.data, %{name: updated_school.name})
                }
              else
                address_changeset =
                  Maps.change_address(%Address{school_location_id: updated_school.id})

                %{
                  address_changeset
                  | data: Map.merge(address_changeset.data, %{name: updated_school.name})
                }
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
          {:noreply,
           put_flash(socket, :error, "Ungültige Adresse. Bitte überprüfen Sie die Eingaben.")}

        {_, {:error, _}} ->
          {:noreply, put_flash(socket, :error, "Fehler beim Aktualisieren der Adresse.")}
      end
    end
  end

  @impl true
  def handle_event("enrich_data", _params, socket) do
    cond do
      socket.assigns.limit_reached ->
        {:noreply,
         put_flash(socket, :error, "Tageslimit erreicht. Keine weiteren Aktionen möglich.")}

      not socket.assigns.api_key_available ->
        {:noreply,
         put_flash(socket, :error, "API-Schlüssel nicht verfügbar. Feature nicht aktiviert.")}

      true ->
        # Start loading
        socket = assign(socket, enrichment_loading: true, enrichment_error: nil)
        school = socket.assigns.school

        # Perform the enrichment in a task
        parent = self()

        Task.start(fn ->
          try do
            case SearchEngineAPI.search_school_by_slug(school.slug, force_refresh: false) do
              {:ok, %{search_results: results}} ->
                # Extract school info
                enriched_data = SearchEngineAPI.extract_school_info(results, school.name)
                send(parent, {:enrichment_complete, enriched_data})

              {:error, reason} ->
                send(parent, {:enrichment_error, reason})
            end
          rescue
            error ->
              send(parent, {:enrichment_error, Exception.message(error)})
          end
        end)

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("apply_enriched_data", %{"fields" => fields}, socket) do
    cond do
      socket.assigns.limit_reached ->
        {:noreply,
         put_flash(socket, :error, "Tageslimit erreicht. Keine weiteren Änderungen möglich.")}

      not socket.assigns.api_key_available ->
        {:noreply,
         put_flash(socket, :error, "API-Schlüssel nicht verfügbar. Feature nicht aktiviert.")}

      true ->
        enriched_data = socket.assigns.enrichment_data
        school = socket.assigns.school

        # Build update params from selected fields
        address_params = %{}

        address_params =
          if Map.get(fields, "homepage_url") == "true" && enriched_data.homepage_url do
            Map.put(address_params, "homepage_url", enriched_data.homepage_url)
          else
            address_params
          end

        address_params =
          if Map.get(fields, "phone_number") == "true" && enriched_data.phone_number do
            Map.put(address_params, "phone_number", enriched_data.phone_number)
          else
            address_params
          end

        address_params =
          if Map.get(fields, "wikipedia_url") == "true" && enriched_data.wikipedia_url do
            Map.put(address_params, "wikipedia_url", enriched_data.wikipedia_url)
          else
            address_params
          end

        address_params =
          if Map.get(fields, "instagram_url") == "true" && enriched_data.instagram_url do
            Map.put(address_params, "instagram_url", enriched_data.instagram_url)
          else
            address_params
          end

        # Add new fields from additional_info
        additional = enriched_data.additional_info || %{}

        address_params =
          if Map.get(fields, "students_count") == "true" && additional[:students_count] do
            # Ensure students_count is an integer
            case Integer.parse(to_string(additional[:students_count])) do
              {count, _} -> Map.put(address_params, "students_count", count)
              :error -> address_params
            end
          else
            address_params
          end

        address_params =
          if Map.get(fields, "founded_year") == "true" && additional[:founded] do
            # Extract year from founded string (e.g., "1850" or "Founded in 1850")
            case Regex.run(~r/\d{4}/, to_string(additional[:founded])) do
              [year_str] -> Map.put(address_params, "founded_year", String.to_integer(year_str))
              _ -> address_params
            end
          else
            address_params
          end

        address_params =
          if Map.get(fields, "description") == "true" && enriched_data.description do
            Map.put(address_params, "description", enriched_data.description)
          else
            address_params
          end

        address_params =
          if Map.get(fields, "street") == "true" && enriched_data.street do
            Map.put(address_params, "street", enriched_data.street)
          else
            address_params
          end

        address_params =
          if Map.get(fields, "zip_code") == "true" && enriched_data.zip_code do
            Map.put(address_params, "zip_code", enriched_data.zip_code)
          else
            address_params
          end

        address_params =
          if Map.get(fields, "city") == "true" && enriched_data.city do
            Map.put(address_params, "city", enriched_data.city)
          else
            address_params
          end

        # If we have anything to update, proceed
        if map_size(address_params) > 0 do
          # Update address if we have address fields
          if map_size(address_params) > 0 do
            # Add required fields
            address_params =
              Map.merge(address_params, %{
                "school_location_id" => school.id,
                "line1" => school.name
              })

            if school.address do
              # Update existing - merge with current address data to preserve fields not being updated
              existing_params = %{
                "street" => school.address.street,
                "zip_code" => school.address.zip_code,
                "city" => school.address.city,
                "email_address" => school.address.email_address,
                "phone_number" => school.address.phone_number,
                "homepage_url" => school.address.homepage_url,
                "wikipedia_url" => school.address.wikipedia_url,
                "instagram_url" => school.address.instagram_url,
                "students_count" => school.address.students_count,
                "founded_year" => school.address.founded_year,
                "description" => school.address.description
              }

              # Merge new params over existing ones
              merged_params = Map.merge(existing_params, address_params)
              changeset = Address.changeset(school.address, merged_params)

              case PaperTrail.update(changeset, meta: %{ip_address: nil}) do
                {:ok, %{version: version}} ->
                  # Increment daily change count if there was a version (actual change)
                  if version do
                    today = Date.utc_today()
                    Wiki.increment_daily_change_count(today)
                  end

                  # Clear enrichment data and reload
                  socket = assign(socket, enrichment_data: nil)

                  # Reload school data
                  updated_school = Locations.get_school_by_slug!(school.slug)
                  versions = get_combined_versions(updated_school)
                  daily_changes = Wiki.get_daily_change_count(Date.utc_today())
                  limit_reached = daily_changes >= Config.daily_change_limit()

                  # Update changeset with new data
                  new_changeset =
                    if updated_school.address do
                      address_changeset = Maps.change_address(updated_school.address)

                      %{
                        address_changeset
                        | data: Map.merge(address_changeset.data, %{name: updated_school.name})
                      }
                    else
                      address_changeset =
                        Maps.change_address(%Address{school_location_id: updated_school.id})

                      %{
                        address_changeset
                        | data: Map.merge(address_changeset.data, %{name: updated_school.name})
                      }
                    end

                  {:noreply,
                   socket
                   |> put_flash(:info, "Angereicherte Daten wurden erfolgreich übernommen.")
                   |> assign(
                     school: updated_school,
                     versions: versions,
                     display_versions: Enum.take(versions, 5),
                     changeset: new_changeset,
                     daily_changes: daily_changes,
                     limit_reached: limit_reached
                   )}

                {:error, %Ecto.Changeset{} = changeset} ->
                  errors =
                    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
                      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
                        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
                      end)
                    end)

                  error_msg =
                    Enum.map_join(errors, ", ", fn {field, msgs} ->
                      "#{field}: #{Enum.join(msgs, ", ")}"
                    end)

                  {:noreply, put_flash(socket, :error, "Fehler beim Speichern: #{error_msg}")}

                {:error, error} ->
                  {:noreply,
                   put_flash(socket, :error, "Fehler beim Speichern der Daten: #{inspect(error)}")}
              end
            else
              # Create new
              changeset = Address.changeset(%Address{}, address_params)

              case PaperTrail.insert(changeset, meta: %{ip_address: nil}) do
                {:ok, %{version: version}} ->
                  # Increment daily change count if there was a version (actual change)
                  if version do
                    today = Date.utc_today()
                    Wiki.increment_daily_change_count(today)
                  end

                  # Clear enrichment data and reload
                  socket = assign(socket, enrichment_data: nil)

                  # Reload school data
                  updated_school = Locations.get_school_by_slug!(school.slug)
                  versions = get_combined_versions(updated_school)
                  daily_changes = Wiki.get_daily_change_count(Date.utc_today())
                  limit_reached = daily_changes >= Config.daily_change_limit()

                  # Update changeset with new data
                  new_changeset =
                    if updated_school.address do
                      address_changeset = Maps.change_address(updated_school.address)

                      %{
                        address_changeset
                        | data: Map.merge(address_changeset.data, %{name: updated_school.name})
                      }
                    else
                      address_changeset =
                        Maps.change_address(%Address{school_location_id: updated_school.id})

                      %{
                        address_changeset
                        | data: Map.merge(address_changeset.data, %{name: updated_school.name})
                      }
                    end

                  {:noreply,
                   socket
                   |> put_flash(:info, "Angereicherte Daten wurden erfolgreich übernommen.")
                   |> assign(
                     school: updated_school,
                     versions: versions,
                     display_versions: Enum.take(versions, 5),
                     changeset: new_changeset,
                     daily_changes: daily_changes,
                     limit_reached: limit_reached
                   )}

                {:error, %Ecto.Changeset{} = changeset} ->
                  errors =
                    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
                      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
                        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
                      end)
                    end)

                  error_msg =
                    Enum.map_join(errors, ", ", fn {field, msgs} ->
                      "#{field}: #{Enum.join(msgs, ", ")}"
                    end)

                  {:noreply, put_flash(socket, :error, "Fehler beim Speichern: #{error_msg}")}

                {:error, error} ->
                  {:noreply,
                   put_flash(socket, :error, "Fehler beim Speichern der Daten: #{inspect(error)}")}
              end
            end
          else
            {:noreply, put_flash(socket, :info, "Keine Felder zum Aktualisieren ausgewählt.")}
          end
        else
          {:noreply, put_flash(socket, :info, "Keine Felder zum Aktualisieren ausgewählt.")}
        end
    end
  end

  @impl true
  def handle_event("cancel_enrichment", _params, socket) do
    {:noreply, assign(socket, enrichment_data: nil, enrichment_error: nil)}
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
      school = socket.assigns.school
      
      # Try to rollback the version to the appropriate model
      rollback_result = attempt_version_rollback(school, version_id)

      case rollback_result do
        {:ok, _} ->
          today = Date.utc_today()
          Wiki.increment_daily_change_count(today)

          # Reload school and data
          updated_school = Locations.get_school_by_slug!(school.slug)
          versions = get_combined_versions(updated_school)
          daily_changes = Wiki.get_daily_change_count(today)
          limit_reached = daily_changes >= Config.daily_change_limit()

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
           |> put_flash(:info, "Erfolgreich zur ausgewählten Version zurückgekehrt.")
           |> assign(
             school: updated_school,
             versions: versions,
             display_versions: Enum.take(versions, 5),
             changeset: changeset,
             daily_changes: daily_changes,
             limit_reached: limit_reached
           )}

        {:error, reason} ->
          error_message = 
            case reason do
              :version_not_found -> "Version nicht gefunden."
              :version_mismatch -> "Version gehört nicht zu diesem Modell."
              :invalid_version_id -> "Ungültige Versions-ID."
              _ -> "Fehler beim Zurückkehren zur ausgewählten Version."
            end

          {:noreply, put_flash(socket, :error, error_message)}
      end
    end
  end

  @impl true
  def handle_info({:email, _email}, socket) do
    # Handle email sending completion - just ignore it
    {:noreply, socket}
  end

  @impl true
  def handle_info({:enrichment_complete, enriched_data}, socket) do
    # Filter enriched data to only show fields that would be updates
    filtered_data = filter_enrichment_updates(enriched_data, socket.assigns.school)

    if has_any_updates?(filtered_data) do
      {:noreply,
       assign(socket,
         enrichment_loading: false,
         enrichment_data: filtered_data,
         enrichment_error: nil
       )}
    else
      {:noreply,
       socket
       |> put_flash(:info, "Keine neuen Daten gefunden. Alle Informationen sind bereits aktuell.")
       |> assign(
         enrichment_loading: false,
         enrichment_error: nil
       )}
    end
  end

  @impl true
  def handle_info({:enrichment_error, reason}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "Fehler beim Abrufen der Daten: #{reason}")
     |> assign(
       enrichment_loading: false,
       enrichment_data: nil,
       enrichment_error: reason
     )}
  end

  # Private helper functions (same as before)
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
    |> Enum.map(&enrich_version_with_changes/1)
  end

  defp enrich_version_with_changes(version) do
    changes = get_version_changes(version)
    change_summary = generate_change_summary(changes)
    
    version
    |> Map.put(:changes, changes)
    |> Map.put(:change_summary, change_summary)
    |> Map.put(:change_count, map_size(changes))
  end

  defp get_version_changes(version) do
    case version.item_type do
      "Location" ->
        # Handle both string and atom keys
        item_changes = version.item_changes || %{}
        cond do
          Map.has_key?(item_changes, "name") ->
            new_name = item_changes["name"]
            old_values = get_previous_values("Location", version.item_id, version)
            old_name = Map.get(old_values, "name") || Map.get(old_values, :name, "")
            %{"Schulname" => {old_name, new_name}}
          Map.has_key?(item_changes, :name) ->
            new_name = item_changes[:name]
            old_values = get_previous_values("Location", version.item_id, version)
            old_name = Map.get(old_values, "name") || Map.get(old_values, :name, "")
            %{"Schulname" => {old_name, new_name}}
          true ->
            %{}
        end
      
      "Address" ->
        old_values = get_previous_values("Address", version.item_id, version)
        
        Enum.reduce(version.item_changes || %{}, %{}, fn {field, new_value}, acc ->
          # Convert field to both string and atom versions for lookup
          field_str = if is_atom(field), do: Atom.to_string(field), else: field
          field_atom = if is_binary(field), do: String.to_atom(field), else: field
          
          field_name =
            case field_str do
              "street" -> "Straße"
              "zip_code" -> "PLZ"
              "city" -> "Stadt"
              "email_address" -> "E-Mail"
              "phone_number" -> "Telefon"
              "homepage_url" -> "Homepage"
              "wikipedia_url" -> "Wikipedia"
              "instagram_url" -> "Instagram"
              "students_count" -> "Schülerzahl"
              "founded_year" -> "Gründungsjahr"
              "description" -> "Beschreibung"
              _ -> nil
            end

          if field_name do
            # Try both string and atom keys in old_values
            old_value = Map.get(old_values, field_str) || Map.get(old_values, field_atom, "")
            
            # Only include changes where there's a meaningful difference
            old_empty = is_nil(old_value) or old_value == ""
            new_empty = is_nil(new_value) or new_value == ""
            
            if old_empty and new_empty do
              # Both empty - no meaningful change
              acc
            else
              Map.put(acc, field_name, {old_value, new_value})
            end
          else
            acc
          end
        end)
      
      _ ->
        %{}
    end
  end

  defp generate_change_summary(changes) when map_size(changes) == 0 do
    "Keine sichtbaren Änderungen"
  end

  defp generate_change_summary(changes) do
    change_descriptions = 
      Enum.map(changes, fn {field_name, {old_value, new_value}} ->
        old_empty = is_nil(old_value) or old_value == ""
        new_empty = is_nil(new_value) or new_value == ""
        
        cond do
          old_empty and not new_empty ->
            "#{field_name} hinzugefügt"
          not old_empty and new_empty ->
            "#{field_name} gelöscht"
          true ->
            "#{field_name} aktualisiert"
        end
      end)
    
    case length(change_descriptions) do
      1 -> List.first(change_descriptions)
      2 -> Enum.join(change_descriptions, " • ")
      n when n > 2 -> 
        first_two = change_descriptions |> Enum.take(2) |> Enum.join(" • ")
        "#{first_two} • #{n - 2} weitere"
    end
  end

  defp gather_changes(school_version, address_version) do
    changes = %{}

    changes =
      if school_version do
        # Get the previous value for the school
        old_values = get_previous_values("Location", school_version.item_id, school_version)

        school_changes =
          if Map.has_key?(school_version.item_changes || %{}, "name") do
            new_name = school_version.item_changes["name"]
            old_name = Map.get(old_values, "name") || Map.get(old_values, :name, "")
            %{"Schulname" => {old_name, new_name}}
          else
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
        Enum.reduce(address_version.item_changes || %{}, %{}, fn {field, new_value}, acc ->
          # Convert field to both string and atom versions for lookup
          field_str = if is_atom(field), do: Atom.to_string(field), else: field
          field_atom = if is_binary(field), do: String.to_atom(field), else: field
          
          field_name =
            case field_str do
              "street" -> "Straße"
              "zip_code" -> "PLZ"
              "city" -> "Stadt"
              "email_address" -> "E-Mail"
              "phone_number" -> "Telefon"
              "homepage_url" -> "Homepage"
              "wikipedia_url" -> "Wikipedia"
              "instagram_url" -> "Instagram"
              "students_count" -> "Schülerzahl"
              "founded_year" -> "Gründungsjahr"
              "description" -> "Beschreibung"
              _ -> nil
            end

          if field_name do
            # Try both string and atom keys in old_values
            old_value = Map.get(old_values, field_str) || Map.get(old_values, field_atom, "")
            
            # Only include changes where there's a meaningful difference
            old_empty = is_nil(old_value) or old_value == ""
            new_empty = is_nil(new_value) or new_value == ""
            
            if old_empty and new_empty do
              # Both empty - no meaningful change
              acc
            else
              Map.put(acc, field_name, {old_value, new_value})
            end
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
      |> Enum.sort_by(& &1.id, :asc)  # Sort ascending to replay changes chronologically

    # Reconstruct the state by replaying all previous versions chronologically
    versions
    |> Enum.reduce(%{}, fn version, state ->
      changes = version.item_changes || %{}
      # Merge changes into the current state, converting keys to consistent format
      merged_changes = 
        changes 
        |> Enum.into(%{}, fn {k, v} -> 
          # Convert atom keys to string keys for consistency
          key = if is_atom(k), do: Atom.to_string(k), else: k
          {key, v}
        end)
      
      Map.merge(state, merged_changes)
    end)
  end

  defp get_country_slug_from_school(school) do
    # Traverse up the hierarchy to find the country
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

  defp attempt_version_rollback(school, version_id) do
    # First, get the version to determine which model it belongs to
    case Repo.get(PaperTrail.Version, String.to_integer(version_id)) do
      nil ->
        {:error, :version_not_found}

      version ->
        # Determine the appropriate model and attempt rollback
        case version.item_type do
          "Location" ->
            # This version is for the school itself
            Wiki.rollback_to_version(school, version_id, nil)

          "Address" ->
            # This version is for the school's address
            if school.address do
              Wiki.rollback_to_version(school.address, version_id, nil)
            else
              {:error, :no_address}
            end

          _ ->
            {:error, :unknown_item_type}
        end
    end
  rescue
    Ecto.NoResultsError ->
      {:error, :version_not_found}
    ArgumentError ->
      {:error, :invalid_version_id}
  end

  defp filter_enrichment_updates(enriched_data, school) do
    address = school.address

    # Filter main fields
    filtered_data = %{
      phone_number: filter_field(enriched_data.phone_number, address && address.phone_number),
      homepage_url: filter_field(enriched_data.homepage_url, address && address.homepage_url),
      wikipedia_url: filter_field(enriched_data.wikipedia_url, address && address.wikipedia_url),
      instagram_url: filter_field(enriched_data.instagram_url, address && address.instagram_url),
      description: filter_field(enriched_data.description, address && address.description),
      street: filter_field(enriched_data.street, address && address.street),
      zip_code: filter_field(enriched_data.zip_code, address && address.zip_code),
      city: filter_field(enriched_data.city, address && address.city),
      additional_info: %{}
    }

    # Filter additional info
    additional = enriched_data.additional_info || %{}

    filtered_additional = %{}

    filtered_additional =
      if additional[:students_count] &&
           additional[:students_count] != (address && address.students_count) do
        Map.put(filtered_additional, :students_count, additional[:students_count])
      else
        filtered_additional
      end

    filtered_additional =
      if additional[:founded] do
        # Extract year from founded string
        founded_year =
          case Regex.run(~r/\d{4}/, to_string(additional[:founded])) do
            [year_str] -> String.to_integer(year_str)
            _ -> nil
          end

        if founded_year && founded_year != (address && address.founded_year) do
          Map.put(filtered_additional, :founded, additional[:founded])
        else
          filtered_additional
        end
      else
        filtered_additional
      end

    # Keep other additional info fields that might be useful
    filtered_additional =
      Enum.reduce(additional, filtered_additional, fn {k, v}, acc ->
        if k not in [:students_count, :founded] do
          Map.put(acc, k, v)
        else
          acc
        end
      end)

    %{filtered_data | additional_info: filtered_additional}
  end

  defp filter_field(new_value, current_value) do
    # Only include if new value exists and is different from current
    if new_value && new_value != "" && new_value != current_value do
      new_value
    else
      nil
    end
  end

  defp has_any_updates?(filtered_data) do
    # Check if any main fields have updates
    main_fields_updated =
      filtered_data.phone_number ||
        filtered_data.homepage_url ||
        filtered_data.wikipedia_url ||
        filtered_data.instagram_url ||
        filtered_data.description ||
        filtered_data.street ||
        filtered_data.zip_code ||
        filtered_data.city

    # Check if any additional fields have updates
    additional_updated =
      filtered_data.additional_info[:students_count] ||
        filtered_data.additional_info[:founded]

    main_fields_updated || additional_updated
  end
end
