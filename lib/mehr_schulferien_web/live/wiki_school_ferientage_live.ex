defmodule MehrSchulferienWeb.WikiSchoolFerientageLive do
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferien.{
    Locations,
    Periods,
    Email,
    Mailer,
    Wiki,
    Config
  }

  alias MehrSchulferienWeb.Formatters.DateFormatter
  alias MehrSchulferien.Helpers.DateParser
  alias MehrSchulferien.Repo

  @impl true
  def mount(%{"slug" => school_slug}, _session, socket) do
    school = Locations.get_school_by_slug!(school_slug)
    # Preload address for UI display
    school = Repo.preload(school, :address)

    # Get daily change count
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)
    limit_reached = daily_changes >= Config.daily_change_limit()

    # Get bewegliche Ferientage for the school
    bewegliche_ferientage = Periods.list_bewegliche_ferientage_for_school(school.id)

    {:ok,
     assign(socket,
       school: school,
       bewegliche_ferientage: bewegliche_ferientage,
       daily_changes: daily_changes,
       limit_reached: limit_reached,
       simple_form_mode: true,
       copy_mode: false,
       search_params: %{
         "search_type" => "zip_code",
         "name_pattern" => "",
         "radius" => "10"
       },
       search_results: [],
       selected_schools: MapSet.new(),
       selected_ferientage: MapSet.new(),
       copy_in_progress: false
     )}
  end

  @impl true
  def handle_event("add_beweglicher_ferientag", %{"ferientag" => params}, socket) do
    if socket.assigns.limit_reached do
      {:noreply,
       put_flash(socket, :error, "Tageslimit erreicht. Keine weiteren Änderungen möglich.")}
    else
      school = socket.assigns.school
      memo = params["memo"]
      today = Date.utc_today()

      case DateParser.parse_dates(params["dates"] || "") do
        {:ok, dates} when dates != [] ->
          # Filter out past dates
          future_dates = Enum.filter(dates, fn date -> Date.compare(date, today) != :lt end)

          if future_dates == [] do
            {:noreply,
             put_flash(
               socket,
               :error,
               "Bewegliche Ferientage können nur für zukünftige Daten angelegt werden."
             )}
          else
            # Check for existing ferientage
            existing_dates =
              Enum.filter(future_dates, fn date ->
                has_beweglicher_ferientag_on_date?(socket.assigns.bewegliche_ferientage, date)
              end)

            if existing_dates != [] do
              date_strings = Enum.map(existing_dates, &DateFormatter.format_date_short/1)

              {:noreply,
               put_flash(
                 socket,
                 :error,
                 "Für folgende Daten existieren bereits bewegliche Ferientage: #{Enum.join(date_strings, ", ")}"
               )}
            else
              # Create ferientage for all dates
              results =
                Enum.map(future_dates, fn date ->
                  Periods.create_beweglicher_ferientag_for_school(school.id, date, memo)
                end)

              successful = Enum.count(results, fn {status, _} -> status == :ok end)
              failed = Enum.count(results, fn {status, _} -> status == :error end)

              if successful > 0 do
                # Send email notification for successful ones
                Enum.each(results, fn
                  {:ok, period} ->
                    Email.beweglicher_ferientag_created_notification(period, school)
                    |> Mailer.deliver!()

                  _ ->
                    :ok
                end)

                # Reload bewegliche Ferientage
                bewegliche_ferientage = Periods.list_bewegliche_ferientage_for_school(school.id)

                message =
                  if failed > 0 do
                    "#{successful} bewegliche Ferientage wurden hinzugefügt. #{failed} konnten nicht angelegt werden."
                  else
                    if successful == 1 do
                      "Beweglicher Ferientag wurde erfolgreich hinzugefügt."
                    else
                      "#{successful} bewegliche Ferientage wurden erfolgreich hinzugefügt."
                    end
                  end

                {:noreply,
                 socket
                 |> put_flash(:info, message)
                 |> assign(bewegliche_ferientage: bewegliche_ferientage)}
              else
                {:noreply,
                 put_flash(socket, :error, "Fehler beim Hinzufügen der beweglichen Ferientage.")}
              end
            end
          end

        {:ok, []} ->
          {:noreply, put_flash(socket, :error, "Bitte geben Sie mindestens ein Datum ein.")}

        {:error, error_message} ->
          {:noreply, put_flash(socket, :error, error_message)}
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
  def handle_event("toggle_form_mode", _params, socket) do
    {:noreply, assign(socket, simple_form_mode: !socket.assigns.simple_form_mode)}
  end

  @impl true
  def handle_event("add_single_ferientag", %{"ferientag" => params}, socket) do
    if socket.assigns.limit_reached do
      {:noreply,
       put_flash(socket, :error, "Tageslimit erreicht. Keine weiteren Änderungen möglich.")}
    else
      school = socket.assigns.school

      # Get date from form
      date_string = params["date"]

      # Get memo directly from the text input
      memo = params["memo"] || ""

      # Parse date
      case Date.from_iso8601(date_string) do
        {:ok, date} ->
          # Check if date is in the future
          if Date.compare(date, Date.utc_today()) != :gt do
            {:noreply,
             put_flash(
               socket,
               :error,
               "Nur zukünftige Daten können als bewegliche Ferientage eingetragen werden."
             )}
          else
            # Check if ferientag already exists on this date
            if has_beweglicher_ferientag_on_date?(socket.assigns.bewegliche_ferientage, date) do
              {:noreply,
               put_flash(
                 socket,
                 :error,
                 "Für dieses Datum existiert bereits ein beweglicher Ferientag."
               )}
            else
              # Create ferientag
              case Periods.create_beweglicher_ferientag_for_school(school.id, date, memo) do
                {:ok, period} ->
                  # Send email notification
                  Email.beweglicher_ferientag_created_notification(period, school)
                  |> Mailer.deliver!()

                  # Reload bewegliche Ferientage
                  bewegliche_ferientage = Periods.list_bewegliche_ferientage_for_school(school.id)

                  # Update daily change count
                  today = Date.utc_today()
                  daily_changes = Wiki.get_daily_change_count(today)
                  limit_reached = daily_changes >= Config.daily_change_limit()

                  {:noreply,
                   socket
                   |> put_flash(:info, "Beweglicher Ferientag wurde erfolgreich hinzugefügt.")
                   |> assign(
                     bewegliche_ferientage: bewegliche_ferientage,
                     daily_changes: daily_changes,
                     limit_reached: limit_reached
                   )}

                {:error, _changeset} ->
                  {:noreply,
                   put_flash(socket, :error, "Fehler beim Hinzufügen des beweglichen Ferientags.")}
              end
            end
          end

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Ungültiges Datumsformat.")}
      end
    end
  end

  @impl true
  def handle_event("toggle_copy_mode", _params, socket) do
    # When toggling copy mode, reset selections
    new_copy_mode = !socket.assigns.copy_mode

    socket =
      if new_copy_mode do
        # When entering copy mode, select all ferientage by default
        all_ferientage_ids = Enum.map(socket.assigns.bewegliche_ferientage, & &1.id)
        assign(socket, selected_ferientage: MapSet.new(all_ferientage_ids))
      else
        # When leaving copy mode, clear selections
        assign(socket,
          selected_ferientage: MapSet.new(),
          selected_schools: MapSet.new(),
          search_results: []
        )
      end

    {:noreply, assign(socket, copy_mode: new_copy_mode)}
  end

  @impl true
  def handle_event("search_schools", %{"search" => params}, socket) do
    if socket.assigns.limit_reached do
      {:noreply,
       put_flash(socket, :error, "Tageslimit erreicht. Keine weiteren Aktionen möglich.")}
    else
      school = Locations.get_school_by_slug!(socket.assigns.school.slug)
      school = Repo.preload(school, :address)

      search_results = perform_school_search(school, params)

      # Enrich results with existing ferientage information
      selected_ferientage_dates = get_selected_ferientage_dates(socket)

      enriched_results =
        enrich_with_existing_ferientage(search_results, selected_ferientage_dates)

      {:noreply,
       assign(socket,
         search_params: params,
         search_results: enriched_results,
         selected_schools: MapSet.new()
       )}
    end
  end

  @impl true
  def handle_event("toggle_school_selection", %{"school-id" => school_id}, socket) do
    school_id = String.to_integer(school_id)
    selected_schools = socket.assigns.selected_schools

    # Find the school in search results to check if it has all dates
    school = Enum.find(socket.assigns.search_results, fn s -> s.id == school_id end)

    # Don't allow selection if school has all selected dates
    if school && Map.get(school, :has_all_selected_dates, false) do
      {:noreply, socket}
    else
      new_selected =
        if MapSet.member?(selected_schools, school_id) do
          MapSet.delete(selected_schools, school_id)
        else
          MapSet.put(selected_schools, school_id)
        end

      {:noreply, assign(socket, selected_schools: new_selected)}
    end
  end

  @impl true
  def handle_event("toggle_ferientag_selection", %{"ferientag-id" => ferientag_id}, socket) do
    ferientag_id = String.to_integer(ferientag_id)
    selected_ferientage = socket.assigns.selected_ferientage

    new_selected =
      if MapSet.member?(selected_ferientage, ferientag_id) do
        MapSet.delete(selected_ferientage, ferientag_id)
      else
        MapSet.put(selected_ferientage, ferientag_id)
      end

    # Update search results if we have any
    updated_socket = assign(socket, selected_ferientage: new_selected)

    if length(socket.assigns.search_results) > 0 do
      update_search_results_enrichment(updated_socket)
    else
      {:noreply, updated_socket}
    end
  end

  @impl true
  def handle_event("select_all_ferientage", _params, socket) do
    all_ferientage_ids = Enum.map(socket.assigns.bewegliche_ferientage, & &1.id)
    updated_socket = assign(socket, selected_ferientage: MapSet.new(all_ferientage_ids))

    if length(socket.assigns.search_results) > 0 do
      update_search_results_enrichment(updated_socket)
    else
      {:noreply, updated_socket}
    end
  end

  @impl true
  def handle_event("deselect_all_ferientage", _params, socket) do
    updated_socket = assign(socket, selected_ferientage: MapSet.new())

    if length(socket.assigns.search_results) > 0 do
      update_search_results_enrichment(updated_socket)
    else
      {:noreply, updated_socket}
    end
  end

  @impl true
  def handle_event("select_all_schools", _params, socket) do
    # Only select schools that don't have all selected dates
    selectable_school_ids =
      socket.assigns.search_results
      |> Enum.reject(fn school -> Map.get(school, :has_all_selected_dates, false) end)
      |> Enum.map(& &1.id)

    {:noreply, assign(socket, selected_schools: MapSet.new(selectable_school_ids))}
  end

  @impl true
  def handle_event("deselect_all_schools", _params, socket) do
    {:noreply, assign(socket, selected_schools: MapSet.new())}
  end

  @impl true
  def handle_event("copy_ferientage", _params, socket) do
    if socket.assigns.limit_reached do
      {:noreply,
       put_flash(socket, :error, "Tageslimit erreicht. Keine weiteren Änderungen möglich.")}
    else
      cond do
        MapSet.size(socket.assigns.selected_ferientage) == 0 ->
          {:noreply,
           put_flash(socket, :error, "Bitte wählen Sie mindestens einen Ferientag aus.")}

        MapSet.size(socket.assigns.selected_schools) == 0 ->
          {:noreply,
           put_flash(socket, :error, "Bitte wählen Sie mindestens eine Zielschule aus.")}

        true ->
          {:noreply, assign(socket, copy_in_progress: true) |> copy_ferientage_to_schools()}
      end
    end
  end

  defp perform_school_search(school, params) do
    case params["search_type"] do
      "zip_code" ->
        Locations.find_schools_by_same_zip_code(school)

      "same_city" ->
        Locations.find_schools_in_same_city(school)

      "radius" ->
        radius = parse_radius(params["radius"] || "10")
        Locations.find_schools_within_radius(school, radius)

      "name_radius" ->
        name_pattern = params["name_pattern"] || ""
        radius = parse_radius(params["radius"] || "50")

        if String.trim(name_pattern) == "" do
          []
        else
          Locations.search_schools_by_name_within_radius(school, name_pattern, radius)
        end

      _ ->
        []
    end
  end

  defp copy_ferientage_to_schools(socket) do
    target_school_ids = MapSet.to_list(socket.assigns.selected_schools)
    selected_ferientage_ids = MapSet.to_list(socket.assigns.selected_ferientage)

    # Filter ferientage to only include selected ones
    selected_ferientage =
      socket.assigns.bewegliche_ferientage
      |> Enum.filter(fn ft -> ft.id in selected_ferientage_ids end)

    case Periods.copy_specific_bewegliche_ferientage(selected_ferientage, target_school_ids) do
      results when is_map(results) ->
        # Count successes and failures
        {success_count, skip_count, error_count, limit_errors, school_count} =
          count_copy_results(results)

        # Send email notifications for successful copies
        send_copy_notifications(results, socket.assigns.school)

        # Update daily change count
        today = Date.utc_today()
        daily_changes = Wiki.get_daily_change_count(today)
        limit_reached = daily_changes >= Config.daily_change_limit()

        message =
          build_copy_result_message(
            success_count,
            skip_count,
            error_count,
            limit_errors,
            school_count
          )

        socket
        |> put_flash(:info, message)
        |> assign(
          copy_in_progress: false,
          selected_schools: MapSet.new(),
          search_results: [],
          copy_mode: false,
          daily_changes: daily_changes,
          limit_reached: limit_reached
        )
        |> push_event("scroll-to-top", %{})

      _ ->
        socket
        |> put_flash(:error, "Fehler beim Kopieren der beweglichen Ferientage.")
        |> assign(copy_in_progress: false)
    end
  end

  defp count_copy_results(results) do
    {success_count, skip_count, error_count, limit_errors, schools_with_success} =
      Enum.reduce(results, {0, 0, 0, 0, 0}, fn {_school_id, school_results},
                                               {succ, skip, err, lim_err, school_count} ->
        # Check if this school has at least one success
        has_success =
          Enum.any?(school_results, fn
            {:success, _} -> true
            _ -> false
          end)

        updated_school_count = if has_success, do: school_count + 1, else: school_count

        result =
          Enum.reduce(school_results, {succ, skip, err, lim_err}, fn
            {:success, _}, {s, sk, e, le} -> {s + 1, sk, e, le}
            {:skipped, _, _}, {s, sk, e, le} -> {s, sk + 1, e, le}
            {:error, _, "Tageslimit erreicht"}, {s, sk, e, le} -> {s, sk, e, le + 1}
            {:error, _, _}, {s, sk, e, le} -> {s, sk, e + 1, le}
          end)

        {elem(result, 0), elem(result, 1), elem(result, 2), elem(result, 3), updated_school_count}
      end)

    {success_count, skip_count, error_count, limit_errors, schools_with_success}
  end

  defp build_copy_result_message(
         success_count,
         skip_count,
         error_count,
         limit_errors,
         school_count
       ) do
    parts = []

    parts =
      if success_count > 0 do
        school_text = if school_count == 1, do: "1 Schule", else: "#{school_count} Schulen"
        ["#{success_count} Ferientage erfolgreich auf #{school_text} kopiert" | parts]
      else
        parts
      end

    parts =
      if skip_count > 0 do
        ["#{skip_count} bereits vorhanden" | parts]
      else
        parts
      end

    parts =
      if error_count > 0 do
        ["#{error_count} Fehler" | parts]
      else
        parts
      end

    parts =
      if limit_errors > 0 do
        ["Tageslimit erreicht" | parts]
      else
        parts
      end

    Enum.join(Enum.reverse(parts), ", ")
  end

  defp send_copy_notifications(results, _source_school) do
    Enum.each(results, fn {target_school_id, school_results} ->
      successful_periods =
        school_results
        |> Enum.filter(fn
          {:success, _} -> true
          _ -> false
        end)
        |> Enum.map(fn {:success, period} -> period end)

      if length(successful_periods) > 0 do
        target_school = Locations.get_location!(target_school_id)

        Enum.each(successful_periods, fn period ->
          Email.beweglicher_ferientag_created_notification(period, target_school)
          |> Mailer.deliver!()
        end)
      end
    end)
  end

  defp has_beweglicher_ferientag_on_date?(ferientage, date) do
    Enum.any?(ferientage, fn ft -> Date.compare(ft.starts_on, date) == :eq end)
  end

  defp parse_radius(radius_string) do
    case Float.parse(radius_string) do
      {radius, _} -> radius
      # Default to 10km if parsing fails
      :error -> 10.0
    end
  end

  defp get_selected_ferientage_dates(socket) do
    selected_ids = MapSet.to_list(socket.assigns.selected_ferientage)

    socket.assigns.bewegliche_ferientage
    |> Enum.filter(fn ft -> ft.id in selected_ids end)
    |> Enum.map(& &1.starts_on)
  end

  defp enrich_with_existing_ferientage(schools, selected_dates) do
    # If no dates are selected, return schools without enrichment
    if selected_dates == [] do
      schools
    else
      Enum.map(schools, fn school ->
        # Get existing ferientage for this school
        existing_ferientage = Periods.list_bewegliche_ferientage_for_school(school.id)
        existing_dates = Enum.map(existing_ferientage, & &1.starts_on)

        # Check which selected dates already exist
        already_has_dates =
          Enum.filter(selected_dates, fn date ->
            Enum.any?(existing_dates, fn existing_date ->
              Date.compare(date, existing_date) == :eq
            end)
          end)

        # Add this information to the school struct
        school
        |> Map.put(:existing_ferientage_dates, already_has_dates)
        |> Map.put(
          :has_all_selected_dates,
          length(already_has_dates) == length(selected_dates) && length(selected_dates) > 0
        )
      end)
    end
  end

  defp update_search_results_enrichment(socket) do
    # Get the current search results
    current_results = socket.assigns.search_results

    # Get selected ferientage dates
    selected_ferientage_dates = get_selected_ferientage_dates(socket)

    # Re-enrich the results
    enriched_results = enrich_with_existing_ferientage(current_results, selected_ferientage_dates)

    # Reset selected schools if needed (remove schools that now have all dates)
    selected_schools = socket.assigns.selected_schools

    updated_selected_schools =
      MapSet.filter(selected_schools, fn school_id ->
        school = Enum.find(enriched_results, fn s -> s.id == school_id end)
        school && !Map.get(school, :has_all_selected_dates, false)
      end)

    {:noreply,
     assign(socket,
       search_results: enriched_results,
       selected_schools: updated_selected_schools
     )}
  end
end
