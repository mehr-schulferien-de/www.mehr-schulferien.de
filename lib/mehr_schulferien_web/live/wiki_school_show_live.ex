defmodule MehrSchulferienWeb.WikiSchoolShowLive do
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferien.{Locations, Maps, Wiki, Email, Mailer, Periods, Config}
  alias MehrSchulferien.Maps.Address
  alias PaperTrail

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
    # Simplified version summary
    case version.item_type do
      "Location" -> "Schulinformationen geändert"
      "Address" -> "Adressinformationen geändert"
      _ -> "Änderung"
    end
  end

  defp has_beweglicher_ferientag_on_date?(ferientage, date) do
    Enum.any?(ferientage, fn ft -> Date.compare(ft.starts_on, date) == :eq end)
  end
end
