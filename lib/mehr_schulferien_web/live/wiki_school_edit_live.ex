defmodule MehrSchulferienWeb.WikiSchoolEditLive do
  use MehrSchulferienWeb, :live_view
  import Ecto.Query

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

    # Get version history
    versions = get_version_history(school)

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
       changeset: changeset,
       daily_changes: daily_changes,
       limit_reached: limit_reached,
       enrichment_loading: false,
       enrichment_data: nil,
       enrichment_error: nil,
       api_key_available: api_key_available,
       show_rollback_preview: false,
       rollback_version: nil,
       show_delete_confirmation: false,
       delete_error: nil
     )}
  end

  @impl true
  def handle_event("validate", %{"address" => address_params} = params, socket) do
    # Get the name from params, default to existing school name if not provided
    name = Map.get(params, "name", socket.assigns.school.name)

    # Create a changeset for validation
    changeset =
      if socket.assigns.school.address do
        # Update existing address with params
        address_changeset = Address.changeset(socket.assigns.school.address, address_params)

        %{
          address_changeset
          | data: Map.merge(address_changeset.data, %{name: name}),
            action: :validate
        }
      else
        # Create new address changeset with validation
        address_changeset =
          Address.changeset(
            %Address{school_location_id: socket.assigns.school.id},
            address_params
          )

        %{
          address_changeset
          | data: Map.merge(address_changeset.data, %{name: name}),
            action: :validate
        }
      end

    {:noreply, assign(socket, changeset: changeset)}
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

      # Store current state for version history
      current_state = capture_current_state(school)

      # Update school name if changed
      school_result =
        if name != school.name do
          location_changeset = MehrSchulferien.Locations.Location.changeset(school, %{name: name})
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

            # Store version with snapshot of previous state
            store_version_snapshot(school, current_state)

            # Reload data
            updated_school = Locations.get_school_by_slug!(school.slug)
            versions = get_version_history(updated_school)
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
                changes = gather_changes(school_version, address_version, current_state)

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
  def handle_event("show_rollback_preview", %{"version_id" => version_id}, socket) do
    version = Enum.find(socket.assigns.versions, &(&1.id == String.to_integer(version_id)))

    if version do
      {:noreply,
       assign(socket,
         show_rollback_preview: true,
         rollback_version: version
       )}
    else
      {:noreply, put_flash(socket, :error, "Version nicht gefunden.")}
    end
  end

  @impl true
  def handle_event("cancel_rollback", _params, socket) do
    {:noreply,
     assign(socket,
       show_rollback_preview: false,
       rollback_version: nil
     )}
  end

  @impl true
  def handle_event("confirm_rollback", %{"version_id" => version_id}, socket) do
    if socket.assigns.limit_reached do
      {:noreply,
       put_flash(
         socket,
         :error,
         "Das tägliche Limit wurde erreicht. Bitte versuchen Sie es morgen erneut."
       )}
    else
      version = Enum.find(socket.assigns.versions, &(&1.id == String.to_integer(version_id)))

      if version && version.snapshot do
        school = socket.assigns.school
        today = Date.utc_today()

        # Restore from snapshot
        result = restore_from_snapshot(school, version.snapshot)

        case result do
          {:ok, _} ->
            Wiki.increment_daily_change_count(today)

            # Reload data
            updated_school = Locations.get_school_by_slug!(school.slug)
            versions = get_version_history(updated_school)
            daily_changes = Wiki.get_daily_change_count(today)
            limit_reached = daily_changes >= Config.daily_change_limit()

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
             |> put_flash(:info, "Erfolgreich zur ausgewählten Version zurückgekehrt.")
             |> assign(
               school: updated_school,
               versions: versions,
               changeset: changeset,
               daily_changes: daily_changes,
               limit_reached: limit_reached,
               show_rollback_preview: false,
               rollback_version: nil
             )}

          {:error, reason} ->
            {:noreply,
             socket
             |> put_flash(:error, "Fehler beim Wiederherstellen: #{reason}")
             |> assign(
               show_rollback_preview: false,
               rollback_version: nil
             )}
        end
      else
        {:noreply,
         socket
         |> put_flash(:error, "Version konnte nicht wiederhergestellt werden.")
         |> assign(
           show_rollback_preview: false,
           rollback_version: nil
         )}
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
                  versions = get_version_history(updated_school)
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
                  versions = get_version_history(updated_school)
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
  def handle_event("show_delete_confirmation", _params, socket) do
    {:noreply, assign(socket, show_delete_confirmation: true, delete_error: nil)}
  end

  @impl true
  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, show_delete_confirmation: false, delete_error: nil)}
  end

  @impl true
  def handle_event(
        "confirm_delete",
        %{"zip_code_confirmation" => zip_code, "deletion_reason" => reason},
        socket
      ) do
    school = socket.assigns.school

    # Verify ZIP code
    expected_zip = if school.address, do: school.address.zip_code, else: nil

    if zip_code == expected_zip || (expected_zip == nil && zip_code == "") do
      # Proceed with deletion
      case Locations.delete_school(school, deletion_reason: reason) do
        {:ok, %{school: _deleted_school}} ->
          # Send email notification asynchronously
          Task.start(fn ->
            try do
              # Reload school with preloaded associations for email
              school_with_address = Repo.preload(school, [:address, :parent_location])
              
              # Get the country slug for the email
              country_slug = get_country_slug_from_school(school_with_address)

              # Send the deletion notification email with reason
              Email.school_deleted_notification(school_with_address, school_with_address.address, country_slug, reason)
              |> Mailer.deliver!()
            rescue
              error ->
                Logger.error("Failed to send school deletion email: #{inspect(error)}")
                Logger.error(Exception.format(:error, error, __STACKTRACE__))
            end
          end)

          # Redirect to a success page or the parent location page
          parent_url =
            if school.parent_location_id do
              parent = Locations.get_location!(school.parent_location_id)

              cond do
                parent.is_city ->
                  ~p"/ferien/d/stadt/#{parent.slug}"

                parent.is_county ->
                  ~p"/ferien/d"  # Counties don't have their own page, redirect to main

                parent.is_federal_state ->
                  ~p"/ferien/d/bundesland/#{parent.slug}"

                true ->
                  ~p"/ferien/d"
              end
            else
              ~p"/ferien/d"
            end

          {:noreply,
           socket
           |> put_flash(
             :info,
             "Die Schule wurde erfolgreich gelöscht. Eine Sicherungskopie wurde per E-Mail versendet."
           )
           |> redirect(to: parent_url)}

        {:error, reason} ->
          {:noreply,
           assign(socket,
             delete_error: "Fehler beim Löschen der Schule: #{inspect(reason)}"
           )}
      end
    else
      {:noreply,
       assign(socket,
         delete_error: "Die eingegebene Postleitzahl stimmt nicht überein."
       )}
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

  # Private helper functions

  defp get_version_history(school) do
    school_versions = PaperTrail.get_versions(school)

    address_versions =
      if school.address do
        PaperTrail.get_versions(school.address)
      else
        []
      end

    # Combine and sort versions
    combined_versions =
      (school_versions ++ address_versions)
      |> Enum.sort_by(& &1.inserted_at, {:desc, NaiveDateTime})
      # Limit to last 20 versions
      |> Enum.take(20)

    # Add snapshot data from cache if available
    Enum.map(combined_versions, fn version ->
      snapshot = get_version_snapshot(version.id)
      changes = extract_changes(version)

      version
      |> Map.put(:snapshot, snapshot)
      |> Map.put(:changes, changes)
      |> Map.put(:description, describe_changes(changes))
    end)
  end

  defp capture_current_state(school) do
    %{
      name: school.name,
      address:
        if school.address do
          %{
            street: school.address.street,
            zip_code: school.address.zip_code,
            city: school.address.city,
            email_address: school.address.email_address,
            phone_number: school.address.phone_number,
            homepage_url: school.address.homepage_url,
            wikipedia_url: school.address.wikipedia_url,
            instagram_url: school.address.instagram_url,
            students_count: school.address.students_count,
            founded_year: school.address.founded_year,
            description: school.address.description
          }
        else
          nil
        end
    }
  end

  defp store_version_snapshot(school, state) do
    # Store snapshot in a simple cache table or as JSON in the version meta
    # For simplicity, we'll use the version meta field
    versions =
      PaperTrail.get_versions(school) ++
        if(school.address, do: PaperTrail.get_versions(school.address), else: [])

    latest_version =
      versions
      |> Enum.sort_by(& &1.inserted_at, {:desc, NaiveDateTime})
      |> List.first()

    if latest_version do
      # Update the version meta with the snapshot
      meta = Map.put(latest_version.meta || %{}, "snapshot", state)

      Repo.update_all(
        from(v in PaperTrail.Version, where: v.id == ^latest_version.id),
        set: [meta: meta]
      )
    end
  end

  defp get_version_snapshot(version_id) do
    version = Repo.get(PaperTrail.Version, version_id)

    if version && version.meta do
      Map.get(version.meta, "snapshot")
    else
      nil
    end
  end

  defp restore_from_snapshot(school, snapshot) do
    Repo.transaction(fn ->
      # Restore school name
      if snapshot["name"] != school.name do
        school_changeset =
          MehrSchulferien.Locations.Location.changeset(school, %{name: snapshot["name"]})

        {:ok, _} = PaperTrail.update(school_changeset, meta: %{ip_address: nil, rollback: true})
      end

      # Restore address
      if snapshot["address"] do
        address_data = snapshot["address"]

        if school.address do
          # Update existing address
          address_changeset = Address.changeset(school.address, address_data)

          {:ok, _} =
            PaperTrail.update(address_changeset, meta: %{ip_address: nil, rollback: true})
        else
          # Create new address if it existed in snapshot
          address_data = Map.put(address_data, "school_location_id", school.id)
          address_data = Map.put(address_data, "line1", snapshot["name"])
          address_changeset = Address.changeset(%Address{}, address_data)

          {:ok, _} =
            PaperTrail.insert(address_changeset, meta: %{ip_address: nil, rollback: true})
        end
      end
    end)
  end

  defp extract_changes(version) do
    changes = version.item_changes || %{}

    # Map field names to German labels
    field_labels = %{
      "name" => "Schulname",
      "street" => "Straße",
      "zip_code" => "PLZ",
      "city" => "Stadt",
      "email_address" => "E-Mail",
      "phone_number" => "Telefon",
      "homepage_url" => "Homepage",
      "wikipedia_url" => "Wikipedia",
      "instagram_url" => "Instagram",
      "students_count" => "Schülerzahl",
      "founded_year" => "Gründungsjahr",
      "description" => "Beschreibung"
    }

    Enum.reduce(changes, %{}, fn {field, new_value}, acc ->
      field_str = if is_atom(field), do: Atom.to_string(field), else: field

      if label = field_labels[field_str] do
        Map.put(acc, label, new_value)
      else
        acc
      end
    end)
  end

  defp describe_changes(changes) when map_size(changes) == 0, do: "Keine Änderungen"

  defp describe_changes(changes) do
    fields = Map.keys(changes)

    case length(fields) do
      1 -> "#{List.first(fields)} geändert"
      2 -> "#{Enum.join(fields, " und ")} geändert"
      n -> "#{Enum.join(Enum.take(fields, 2), ", ")} und #{n - 2} weitere geändert"
    end
  end

  defp gather_changes(school_version, address_version, previous_state) do
    changes = %{}

    changes =
      if school_version && school_version.item_changes["name"] do
        Map.put(changes, "Schulname", {
          previous_state.name,
          school_version.item_changes["name"]
        })
      else
        changes
      end

    changes =
      if address_version do
        Enum.reduce(address_version.item_changes || %{}, changes, fn {field, new_value}, acc ->
          field_str = if is_atom(field), do: Atom.to_string(field), else: field

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
            old_value =
              if previous_state.address do
                Map.get(previous_state.address, String.to_atom(field_str))
              else
                nil
              end

            Map.put(acc, field_name, {old_value, new_value})
          else
            acc
          end
        end)
      else
        changes
      end

    changes
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
