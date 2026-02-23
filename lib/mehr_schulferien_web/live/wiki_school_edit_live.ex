defmodule MehrSchulferienWeb.WikiSchoolEditLive do
  use MehrSchulferienWeb, :live_view

  on_mount {MehrSchulferienWeb.WikiAuth, :require_auth}

  alias MehrSchulferien.{
    Blacklist,
    Config,
    Locations,
    Maps,
    Repo,
    Wiki
  }

  alias MehrSchulferien.Maps.Address
  alias MehrSchulferien.Wiki.PendingChanges
  alias PaperTrail

  # Shared field labels for version history display
  @field_labels %{
    "name" => "Schulname",
    "street" => "Straße",
    "zip_code" => "PLZ",
    "city" => "Stadt",
    "email_address" => "E-Mail",
    "phone_number" => "Telefon",
    "homepage_url" => "Homepage",
    "schuelerzeitung_url" => "Schülerzeitung",
    "wikipedia_url" => "Wikipedia",
    "instagram_url" => "Instagram",
    "students_count" => "Schülerzahl",
    "founded_year" => "Gründungsjahr",
    "description" => "Beschreibung"
  }

  @impl true
  def mount(%{"slug" => school_slug}, _session, socket) do
    school = Locations.get_school_by_slug!(school_slug)

    # Get version history
    versions = get_version_history(school)

    # Get daily change count
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)
    limit_reached = daily_changes >= Config.daily_change_limit()

    # Store original zip code for detecting significant changes
    original_zip_code = if school.address, do: school.address.zip_code, else: nil

    # Create a combined changeset for both school and address fields
    changeset = build_school_changeset(school)

    {:ok,
     assign(socket,
       school: school,
       versions: versions,
       changeset: changeset,
       daily_changes: daily_changes,
       limit_reached: limit_reached,
       show_rollback_preview: false,
       rollback_version: nil,
       show_delete_confirmation: false,
       delete_error: nil,
       original_zip_code: original_zip_code,
       show_new_school_hint: false,
       blacklist_error: nil,
       school_contact_info_enabled: Config.school_contact_info_enabled?()
     )}
  end

  @impl true
  def handle_event("validate", %{"address" => address_params} = params, socket) do
    # Get the name from params, default to existing school name if not provided
    name = Map.get(params, "name", socket.assigns.school.name)

    # Check if zip code has changed significantly (to a different valid 5-digit zip code)
    new_zip_code = Map.get(address_params, "zip_code", "")
    original_zip_code = socket.assigns.original_zip_code

    show_new_school_hint =
      zip_code_changed_significantly?(original_zip_code, new_zip_code)

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

    # Check for blacklisted values
    blacklist_error =
      case Blacklist.check_params_for_blacklisted_values(address_params) do
        :ok -> nil
        {:error, blocked_fields} -> Blacklist.format_blocked_fields_error(blocked_fields)
      end

    {:noreply,
     assign(socket,
       changeset: changeset,
       show_new_school_hint: show_new_school_hint,
       blacklist_error: blacklist_error
     )}
  end

  @impl true
  def handle_event("update_school", %{"address" => address_params, "name" => name}, socket) do
    cond do
      socket.assigns.limit_reached ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Das tägliche Limit von #{Config.daily_change_limit()} Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
         )}

      # Check blacklist before allowing any changes
      match?({:error, _}, Blacklist.check_params_for_blacklisted_values(address_params)) ->
        {:error, blocked_fields} = Blacklist.check_params_for_blacklisted_values(address_params)
        error_message = Blacklist.format_blocked_fields_error(blocked_fields)
        {:noreply, put_flash(socket, :error, error_message)}

      true ->
        school = socket.assigns.school

        # Submit to pending changes queue instead of directly updating
        pending_attrs = %{
          change_type: "update_school",
          payload: %{
            "school_name" => name,
            "address_params" => address_params
          },
          original_record_id: school.id,
          submitted_by_ip: get_client_ip(socket)
        }

        case PendingChanges.create_pending_change(pending_attrs) do
          {:ok, _pending_change} ->
            Wiki.increment_daily_change_count(Date.utc_today())

            {:noreply,
             socket
             |> put_flash(
               :info,
               "Ihre Änderung wurde zur Überprüfung eingereicht. Sie wird nach Genehmigung auf der Seite sichtbar."
             )
             |> redirect(to: ~p"/wiki")}

          {:error, _changeset} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "Fehler beim Einreichen der Änderung. Bitte versuchen Sie es erneut."
             )}
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

            {:noreply,
             socket
             |> put_flash(:info, "Erfolgreich zur ausgewählten Version zurückgekehrt.")
             |> assign(
               school: updated_school,
               versions: versions,
               changeset: build_school_changeset(updated_school),
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
      # Submit to pending changes queue instead of directly deleting
      pending_attrs = %{
        change_type: "delete_school",
        payload: %{
          "school_name" => school.name,
          "deletion_reason" => reason
        },
        original_record_id: school.id,
        submitted_by_ip: get_client_ip(socket)
      }

      case PendingChanges.create_pending_change(pending_attrs) do
        {:ok, _pending_change} ->
          Wiki.increment_daily_change_count(Date.utc_today())

          {:noreply,
           socket
           |> put_flash(
             :info,
             "Ihre Löschanfrage wurde zur Überprüfung eingereicht. Sie wird nach Genehmigung umgesetzt."
           )
           |> redirect(to: ~p"/wiki")}

        {:error, _changeset} ->
          {:noreply,
           assign(socket,
             delete_error:
               "Fehler beim Einreichen der Löschanfrage. Bitte versuchen Sie es erneut."
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

  # Private helper functions

  defp get_client_ip(socket) do
    case socket.assigns[:remote_ip] do
      {a, b, c, d} -> "#{a}.#{b}.#{c}.#{d}"
      _ -> "unknown"
    end
  end

  # Creates a changeset for school address with the school name merged into data
  defp build_school_changeset(school) do
    address_changeset =
      if school.address do
        Maps.change_address(school.address)
      else
        Maps.change_address(%Address{school_location_id: school.id})
      end

    %{address_changeset | data: Map.merge(address_changeset.data, %{name: school.name})}
  end

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

    Enum.reduce(changes, %{}, fn {field, new_value}, acc ->
      field_str = if is_atom(field), do: Atom.to_string(field), else: field

      if label = @field_labels[field_str] do
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

  # Check if the zip code has changed to a different valid 5-digit German zip code
  defp zip_code_changed_significantly?(original, new)
       when is_binary(original) and is_binary(new) do
    # Only show hint if:
    # 1. Both are valid 5-digit zip codes
    # 2. They are different
    String.length(original) == 5 and
      String.length(new) == 5 and
      String.match?(new, ~r/^\d{5}$/) and
      original != new
  end

  defp zip_code_changed_significantly?(_, _), do: false
end
