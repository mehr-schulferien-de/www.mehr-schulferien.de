defmodule MehrSchulferienWeb.WikiSchoolFerientageLive do
  use MehrSchulferienWeb, :live_view

  on_mount {MehrSchulferienWeb.WikiAuth, :require_auth}

  alias MehrSchulferien.{
    Config,
    Email,
    Locations,
    Mailer,
    Periods,
    Wiki
  }

  alias MehrSchulferien.Helpers.DateParser
  alias MehrSchulferien.Repo
  alias MehrSchulferienWeb.Formatters.DateFormatter

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

    # Get federal state and limit information
    federal_state = Periods.get_school_federal_state(school.id)
    current_school_year = Periods.get_school_year_for_date(today)

    # Get limits for current and next 2 school years
    school_years_data =
      case federal_state do
        nil ->
          []

        _ ->
          # Calculate next school years
          current_year = if today.month >= 8, do: today.year, else: today.year - 1

          school_years = [
            "#{current_year}/#{current_year + 1}",
            "#{current_year + 1}/#{current_year + 2}",
            "#{current_year + 2}/#{current_year + 3}"
          ]

          school_years
          |> Enum.map(fn school_year ->
            limit = Periods.get_federal_state_ferientage_limit(federal_state.id, school_year)
            count = Periods.count_bewegliche_ferientage_for_school_year(school.id, school_year)
            remaining = if limit, do: limit.max_bewegliche_ferientage * 2 - count, else: nil

            %{
              school_year: school_year,
              limit: limit,
              count: count,
              remaining: remaining,
              is_current: school_year == current_school_year
            }
          end)
          |> Enum.filter(fn year_data ->
            year_data.limit && year_data.limit.max_bewegliche_ferientage > 0
          end)
      end

    # Adjust selected school year if it's not in the filtered list
    adjusted_selected_school_year =
      if Enum.any?(school_years_data, &(&1.school_year == current_school_year)) do
        current_school_year
      else
        # Select the first available year or keep current if no years available
        case school_years_data do
          [first | _] -> first.school_year
          [] -> current_school_year
        end
      end

    # Keep single values for backward compatibility (selected year)
    selected_year_data =
      Enum.find(school_years_data, &(&1.school_year == adjusted_selected_school_year)) ||
        %{limit: nil, count: 0, remaining: nil}

    {ferientage_limit, current_count, remaining_ferientage} =
      {selected_year_data.limit, selected_year_data.count, selected_year_data.remaining}

    # Get bewegliche ferientage from other schools with same zip code
    other_schools_ferientage =
      if school.address && school.address.zip_code && bewegliche_ferientage == [] do
        schools_same_zip = Locations.find_schools_by_same_zip_code(school)

        schools_same_zip
        |> Enum.flat_map(fn other_school ->
          Periods.list_bewegliche_ferientage_for_school(other_school.id)
          |> Enum.map(fn period ->
            Map.put(period, :school_name, other_school.name)
          end)
        end)
        |> Enum.uniq_by(fn period -> {period.starts_on, period.memo} end)
        |> Enum.sort_by(& &1.starts_on)
      else
        []
      end

    # Pre-select all ferientage for copying
    selected_ferientage_ids =
      if bewegliche_ferientage != [] do
        MapSet.new(Enum.map(bewegliche_ferientage, & &1.id))
      else
        MapSet.new()
      end

    # Initial search parameters
    initial_search_params = %{
      "search_type" => "zip_code",
      "name_pattern" => "",
      "radius" => "10"
    }

    # Perform initial search if we have bewegliche ferientage to copy
    initial_search_results =
      if bewegliche_ferientage != [] && !limit_reached do
        search_results = perform_school_search(school, initial_search_params)
        selected_dates = Enum.map(bewegliche_ferientage, & &1.starts_on)
        enrich_with_existing_ferientage(search_results, selected_dates)
      else
        []
      end

    # Add selected school year tracking
    selected_school_year = adjusted_selected_school_year

    # Filter bewegliche ferientage for the selected school year
    filtered_ferientage =
      filter_ferientage_by_school_year(bewegliche_ferientage, selected_school_year)

    {:ok,
     assign(socket,
       school: school,
       bewegliche_ferientage: bewegliche_ferientage,
       filtered_ferientage: filtered_ferientage,
       selected_school_year: selected_school_year,
       other_schools_ferientage: other_schools_ferientage,
       daily_changes: daily_changes,
       limit_reached: limit_reached,
       federal_state: federal_state,
       current_school_year: current_school_year,
       ferientage_limit: ferientage_limit,
       current_ferientage_count: current_count,
       remaining_ferientage: remaining_ferientage,
       school_years_data: school_years_data,
       simple_form_mode: true,
       copy_mode: true,
       search_params: initial_search_params,
       search_results: initial_search_results,
       selected_schools: MapSet.new(),
       selected_ferientage: selected_ferientage_ids,
       copy_in_progress: false,
       quick_copy_ferientage: MapSet.new(),
       show_copy_confirmation_modal: false,
       would_exceed_limit: false,
       required_changes: 0,
       remaining_quota: Config.daily_change_limit() - daily_changes
     )}
  end

  @impl true
  def handle_event("add_beweglicher_ferientag", %{"ferientag" => params}, socket) do
    if socket.assigns.limit_reached do
      {:noreply,
       socket
       |> clear_flash()
       |> put_flash(:error, "Tageslimit erreicht. Keine weiteren Änderungen möglich.")}
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
             socket
             |> clear_flash()
             |> put_flash(
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
               socket
               |> clear_flash()
               |> put_flash(
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

                # Recalculate federal state limit information
                today = Date.utc_today()
                current_school_year = Periods.get_school_year_for_date(today)

                # Recalculate school years data
                school_years_data =
                  if socket.assigns.federal_state do
                    current_year = if today.month >= 8, do: today.year, else: today.year - 1

                    school_years = [
                      "#{current_year}/#{current_year + 1}",
                      "#{current_year + 1}/#{current_year + 2}",
                      "#{current_year + 2}/#{current_year + 3}"
                    ]

                    school_years
                    |> Enum.map(fn school_year ->
                      limit =
                        Periods.get_federal_state_ferientage_limit(
                          socket.assigns.federal_state.id,
                          school_year
                        )

                      count =
                        Periods.count_bewegliche_ferientage_for_school_year(
                          school.id,
                          school_year
                        )

                      remaining =
                        if limit, do: limit.max_bewegliche_ferientage * 2 - count, else: nil

                      %{
                        school_year: school_year,
                        limit: limit,
                        count: count,
                        remaining: remaining,
                        is_current: school_year == current_school_year
                      }
                    end)
                    |> Enum.filter(fn year_data ->
                      year_data.limit && year_data.limit.max_bewegliche_ferientage > 0
                    end)
                  else
                    []
                  end

                # Get current year data for backward compatibility
                current_year_data =
                  Enum.find(school_years_data, & &1.is_current) || %{count: 0, remaining: nil}

                {current_count, remaining_ferientage} =
                  {current_year_data.count, current_year_data.remaining}

                message =
                  if failed > 0 do
                    # Check if any failures were due to limit
                    limit_errors =
                      Enum.filter(results, fn
                        {:error, reason} when is_binary(reason) ->
                          String.contains?(reason, "maximale Anzahl")

                        _ ->
                          false
                      end)

                    # Check if any failures were due to non-school days
                    no_school_day_errors =
                      Enum.filter(results, fn
                        {:error, reason} when is_binary(reason) ->
                          String.contains?(reason, "schulfreier Tag")

                        _ ->
                          false
                      end)

                    cond do
                      no_school_day_errors != [] ->
                        "#{successful} bewegliche Ferientage wurden hinzugefügt. #{failed} konnten nicht angelegt werden (bereits schulfreie Tage)."

                      limit_errors != [] ->
                        "#{successful} bewegliche Ferientage wurden hinzugefügt. #{failed} konnten nicht angelegt werden (Limit erreicht)."

                      true ->
                        "#{successful} bewegliche Ferientage wurden hinzugefügt. #{failed} konnten nicht angelegt werden."
                    end
                  else
                    if successful == 1 do
                      "Beweglicher Ferientag wurde erfolgreich hinzugefügt."
                    else
                      "#{successful} bewegliche Ferientage wurden erfolgreich hinzugefügt."
                    end
                  end

                # Update filtered ferientage
                filtered_ferientage =
                  filter_ferientage_by_school_year(
                    bewegliche_ferientage,
                    socket.assigns.selected_school_year
                  )

                {:noreply,
                 socket
                 |> clear_flash()
                 |> put_flash(:info, message)
                 |> assign(
                   bewegliche_ferientage: bewegliche_ferientage,
                   filtered_ferientage: filtered_ferientage,
                   current_ferientage_count: current_count,
                   remaining_ferientage: remaining_ferientage,
                   school_years_data: school_years_data
                 )}
              else
                # All failed - show the specific error message from the first failure
                error_message =
                  case Enum.at(results, 0) do
                    {:error, msg} when is_binary(msg) -> msg
                    _ -> "Fehler beim Hinzufügen der beweglichen Ferientage."
                  end

                {:noreply, socket |> clear_flash() |> put_flash(:error, error_message)}
              end
            end
          end

        {:ok, []} ->
          {:noreply,
           socket
           |> clear_flash()
           |> put_flash(:error, "Bitte geben Sie mindestens ein Datum ein.")}

        {:error, error_message} ->
          {:noreply, socket |> clear_flash() |> put_flash(:error, error_message)}
      end
    end
  end

  @impl true
  def handle_event("delete_beweglicher_ferientag", %{"id" => id}, socket) do
    if socket.assigns.limit_reached do
      {:noreply,
       socket
       |> clear_flash()
       |> put_flash(:error, "Tageslimit erreicht. Keine weiteren Änderungen möglich.")}
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

          # Update filtered ferientage
          filtered_ferientage =
            filter_ferientage_by_school_year(
              bewegliche_ferientage,
              socket.assigns.selected_school_year
            )

          # Recalculate counts for current school year
          current_year_data =
            Enum.find(
              socket.assigns.school_years_data,
              &(&1.school_year == socket.assigns.selected_school_year)
            )

          if current_year_data do
            updated_count =
              Periods.count_bewegliche_ferientage_for_school_year(
                school.id,
                socket.assigns.selected_school_year
              )

            updated_remaining =
              if current_year_data.limit,
                do: current_year_data.limit.max_bewegliche_ferientage * 2 - updated_count,
                else: nil

            # Update school_years_data
            updated_school_years_data =
              Enum.map(socket.assigns.school_years_data, fn data ->
                if data.school_year == socket.assigns.selected_school_year do
                  %{data | count: updated_count, remaining: updated_remaining}
                else
                  data
                end
              end)

            {:noreply,
             socket
             |> clear_flash()
             |> put_flash(:info, "Beweglicher Ferientag wurde gelöscht.")
             |> assign(
               bewegliche_ferientage: bewegliche_ferientage,
               filtered_ferientage: filtered_ferientage,
               current_ferientage_count: updated_count,
               remaining_ferientage: updated_remaining,
               school_years_data: updated_school_years_data
             )}
          else
            {:noreply,
             socket
             |> clear_flash()
             |> put_flash(:info, "Beweglicher Ferientag wurde gelöscht.")
             |> assign(
               bewegliche_ferientage: bewegliche_ferientage,
               filtered_ferientage: filtered_ferientage
             )}
          end

        {:error, _changeset} ->
          {:noreply,
           socket
           |> clear_flash()
           |> put_flash(:error, "Fehler beim Löschen des beweglichen Ferientags.")}
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
       socket
       |> clear_flash()
       |> put_flash(:error, "Tageslimit erreicht. Keine weiteren Änderungen möglich.")}
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
             socket
             |> clear_flash()
             |> put_flash(
               :error,
               "Nur zukünftige Daten können als bewegliche Ferientage eingetragen werden."
             )}
          else
            # Check if ferientag already exists on this date
            if has_beweglicher_ferientag_on_date?(socket.assigns.bewegliche_ferientage, date) do
              {:noreply,
               socket
               |> clear_flash()
               |> put_flash(
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

                  # Update filtered ferientage
                  filtered_ferientage =
                    filter_ferientage_by_school_year(
                      bewegliche_ferientage,
                      socket.assigns.selected_school_year
                    )

                  # Update daily change count
                  today = Date.utc_today()
                  daily_changes = Wiki.get_daily_change_count(today)
                  limit_reached = daily_changes >= Config.daily_change_limit()

                  # Recalculate counts for current school year
                  current_year_data =
                    Enum.find(
                      socket.assigns.school_years_data,
                      &(&1.school_year == socket.assigns.selected_school_year)
                    )

                  if current_year_data do
                    updated_count =
                      Periods.count_bewegliche_ferientage_for_school_year(
                        school.id,
                        socket.assigns.selected_school_year
                      )

                    updated_remaining =
                      if current_year_data.limit,
                        do: current_year_data.limit.max_bewegliche_ferientage * 2 - updated_count,
                        else: nil

                    # Update school_years_data
                    updated_school_years_data =
                      Enum.map(socket.assigns.school_years_data, fn data ->
                        if data.school_year == socket.assigns.selected_school_year do
                          %{data | count: updated_count, remaining: updated_remaining}
                        else
                          data
                        end
                      end)

                    {:noreply,
                     socket
                     |> clear_flash()
                     |> put_flash(:info, "Beweglicher Ferientag wurde erfolgreich hinzugefügt.")
                     |> assign(
                       bewegliche_ferientage: bewegliche_ferientage,
                       filtered_ferientage: filtered_ferientage,
                       daily_changes: daily_changes,
                       limit_reached: limit_reached,
                       current_ferientage_count: updated_count,
                       remaining_ferientage: updated_remaining,
                       school_years_data: updated_school_years_data
                     )}
                  else
                    {:noreply,
                     socket
                     |> clear_flash()
                     |> put_flash(:info, "Beweglicher Ferientag wurde erfolgreich hinzugefügt.")
                     |> assign(
                       bewegliche_ferientage: bewegliche_ferientage,
                       filtered_ferientage: filtered_ferientage,
                       daily_changes: daily_changes,
                       limit_reached: limit_reached
                     )}
                  end

                {:error, error_message} when is_binary(error_message) ->
                  {:noreply, socket |> clear_flash() |> put_flash(:error, error_message)}

                {:error, _changeset} ->
                  {:noreply,
                   socket
                   |> clear_flash()
                   |> put_flash(:error, "Fehler beim Hinzufügen des beweglichen Ferientags.")}
              end
            end
          end

        {:error, _} ->
          {:noreply, socket |> clear_flash() |> put_flash(:error, "Ungültiges Datumsformat.")}
      end
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

    if socket.assigns.search_results != [] do
      update_search_results_enrichment(updated_socket)
    else
      {:noreply, updated_socket}
    end
  end

  @impl true
  def handle_event("select_all_ferientage", _params, socket) do
    all_ferientage_ids = Enum.map(socket.assigns.bewegliche_ferientage, & &1.id)
    updated_socket = assign(socket, selected_ferientage: MapSet.new(all_ferientage_ids))

    if socket.assigns.search_results != [] do
      update_search_results_enrichment(updated_socket)
    else
      {:noreply, updated_socket}
    end
  end

  @impl true
  def handle_event("deselect_all_ferientage", _params, socket) do
    updated_socket = assign(socket, selected_ferientage: MapSet.new())

    if socket.assigns.search_results != [] do
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
  def handle_event("update_search_params", %{"search" => params}, socket) do
    if socket.assigns.limit_reached do
      {:noreply, socket}
    else
      # Update search params while preserving existing values
      updated_params = Map.merge(socket.assigns.search_params, params)

      # Ensure radius doesn't exceed 50
      updated_params =
        if updated_params["radius"] do
          radius_value =
            case Integer.parse(updated_params["radius"]) do
              {num, _} -> min(num, 50) |> max(1)
              :error -> 10
            end

          Map.put(updated_params, "radius", to_string(radius_value))
        else
          updated_params
        end

      # Automatically perform search
      school = Locations.get_school_by_slug!(socket.assigns.school.slug)
      school = Repo.preload(school, :address)

      search_results = perform_school_search(school, updated_params)

      # Enrich results with existing ferientage information
      selected_ferientage_dates = get_selected_ferientage_dates(socket)

      enriched_results =
        enrich_with_existing_ferientage(search_results, selected_ferientage_dates)

      {:noreply,
       assign(socket,
         search_params: updated_params,
         search_results: enriched_results,
         selected_schools: MapSet.new()
       )}
    end
  end

  @impl true
  def handle_event("toggle_quick_copy_selection", %{"date" => date_str, "memo" => memo}, socket) do
    key = {date_str, memo}
    quick_copy_ferientage = socket.assigns.quick_copy_ferientage

    new_selected =
      if MapSet.member?(quick_copy_ferientage, key) do
        MapSet.delete(quick_copy_ferientage, key)
      else
        MapSet.put(quick_copy_ferientage, key)
      end

    {:noreply, assign(socket, quick_copy_ferientage: new_selected)}
  end

  @impl true
  def handle_event("quick_copy_ferientage", _params, socket) do
    if socket.assigns.limit_reached do
      {:noreply,
       socket
       |> clear_flash()
       |> put_flash(:error, "Tageslimit erreicht. Keine weiteren Änderungen möglich.")}
    else
      if MapSet.size(socket.assigns.quick_copy_ferientage) == 0 do
        {:noreply,
         socket
         |> clear_flash()
         |> put_flash(:error, "Bitte wählen Sie mindestens einen Ferientag aus.")}
      else
        # Create bewegliche ferientage for selected dates
        school = socket.assigns.school
        today = Date.utc_today()

        results =
          socket.assigns.quick_copy_ferientage
          |> Enum.map(fn {date_str, memo} ->
            case Date.from_iso8601(date_str) do
              {:ok, date} ->
                if Date.compare(date, today) == :gt do
                  Periods.create_beweglicher_ferientag_for_school(school.id, date, memo)
                else
                  {:error, "Past date"}
                end

              _ ->
                {:error, "Invalid date"}
            end
          end)

        successful = Enum.count(results, fn {status, _} -> status == :ok end)

        if successful > 0 do
          # Send email notifications for successful ones
          Enum.each(results, fn
            {:ok, period} ->
              Email.beweglicher_ferientag_created_notification(period, school)
              |> Mailer.deliver!()

            _ ->
              :ok
          end)

          # Reload bewegliche Ferientage
          bewegliche_ferientage = Periods.list_bewegliche_ferientage_for_school(school.id)

          # Update filtered ferientage
          filtered_ferientage =
            filter_ferientage_by_school_year(
              bewegliche_ferientage,
              socket.assigns.selected_school_year
            )

          # Update daily change count
          daily_changes = Wiki.get_daily_change_count(today)
          limit_reached = daily_changes >= Config.daily_change_limit()

          message =
            if successful == 1 do
              "Beweglicher Ferientag wurde erfolgreich hinzugefügt."
            else
              "#{successful} bewegliche Ferientage wurden erfolgreich hinzugefügt."
            end

          {:noreply,
           socket
           |> clear_flash()
           |> put_flash(:info, message)
           |> assign(
             bewegliche_ferientage: bewegliche_ferientage,
             filtered_ferientage: filtered_ferientage,
             other_schools_ferientage: [],
             quick_copy_ferientage: MapSet.new(),
             daily_changes: daily_changes,
             limit_reached: limit_reached
           )}
        else
          {:noreply,
           socket
           |> clear_flash()
           |> put_flash(:error, "Fehler beim Hinzufügen der beweglichen Ferientage.")}
        end
      end
    end
  end

  @impl true
  def handle_event("show_copy_confirmation", _params, socket) do
    if socket.assigns.limit_reached do
      {:noreply,
       socket
       |> clear_flash()
       |> put_flash(:error, "Tageslimit erreicht. Keine weiteren Änderungen möglich.")}
    else
      cond do
        MapSet.size(socket.assigns.selected_ferientage) == 0 ->
          {:noreply,
           socket
           |> clear_flash()
           |> put_flash(:error, "Bitte wählen Sie mindestens einen Ferientag aus.")}

        MapSet.size(socket.assigns.selected_schools) == 0 ->
          {:noreply,
           socket
           |> clear_flash()
           |> put_flash(:error, "Bitte wählen Sie mindestens eine Zielschule aus.")}

        true ->
          # Calculate if this operation would exceed the daily limit
          required_changes = calculate_required_changes(socket)
          remaining_quota = Config.daily_change_limit() - socket.assigns.daily_changes
          would_exceed_limit = required_changes > remaining_quota

          {:noreply,
           assign(socket,
             show_copy_confirmation_modal: true,
             would_exceed_limit: would_exceed_limit,
             required_changes: required_changes,
             remaining_quota: remaining_quota
           )}
      end
    end
  end

  @impl true
  def handle_event("close_copy_confirmation", _params, socket) do
    {:noreply, assign(socket, show_copy_confirmation_modal: false)}
  end

  @impl true
  def handle_event("copy_ferientage", _params, socket) do
    if socket.assigns.limit_reached do
      {:noreply,
       socket
       |> clear_flash()
       |> put_flash(:error, "Tageslimit erreicht. Keine weiteren Änderungen möglich.")}
    else
      cond do
        MapSet.size(socket.assigns.selected_ferientage) == 0 ->
          {:noreply,
           socket
           |> clear_flash()
           |> put_flash(:error, "Bitte wählen Sie mindestens einen Ferientag aus.")}

        MapSet.size(socket.assigns.selected_schools) == 0 ->
          {:noreply,
           socket
           |> clear_flash()
           |> put_flash(:error, "Bitte wählen Sie mindestens eine Zielschule aus.")}

        true ->
          {:noreply,
           socket
           |> assign(copy_in_progress: true, show_copy_confirmation_modal: false)
           |> copy_ferientage_to_schools()}
      end
    end
  end

  @impl true
  def handle_event("select_school_year", %{"school_year" => school_year}, socket) do
    # Update selected school year and filter ferientage
    filtered_ferientage =
      filter_ferientage_by_school_year(socket.assigns.bewegliche_ferientage, school_year)

    # Get the selected year's data
    selected_year_data =
      Enum.find(socket.assigns.school_years_data, fn data ->
        data.school_year == school_year
      end)

    {:noreply,
     assign(socket,
       selected_school_year: school_year,
       filtered_ferientage: filtered_ferientage,
       ferientage_limit: selected_year_data && selected_year_data.limit,
       current_ferientage_count: (selected_year_data && selected_year_data.count) || 0,
       remaining_ferientage: selected_year_data && selected_year_data.remaining
     )}
  end

  @impl true
  def handle_event("navigate_year", %{"direction" => direction}, socket) do
    current_index =
      Enum.find_index(socket.assigns.school_years_data, fn data ->
        data.school_year == socket.assigns.selected_school_year
      end)

    new_index =
      case direction do
        "prev" -> max(0, current_index - 1)
        "next" -> min(length(socket.assigns.school_years_data) - 1, current_index + 1)
      end

    new_year_data = Enum.at(socket.assigns.school_years_data, new_index)

    if new_year_data && new_year_data.school_year != socket.assigns.selected_school_year do
      # Reuse the select_school_year logic
      filtered_ferientage =
        filter_ferientage_by_school_year(
          socket.assigns.bewegliche_ferientage,
          new_year_data.school_year
        )

      {:noreply,
       assign(socket,
         selected_school_year: new_year_data.school_year,
         filtered_ferientage: filtered_ferientage,
         ferientage_limit: new_year_data.limit,
         current_ferientage_count: new_year_data.count || 0,
         remaining_ferientage: new_year_data.remaining
       )}
    else
      {:noreply, socket}
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
        radius = parse_radius(params["radius"] || "10")

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
        send_copy_notifications(results, socket.assigns.school, selected_ferientage)

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
        |> clear_flash()
        |> put_flash(:info, message)
        |> assign(
          copy_in_progress: false,
          selected_schools: MapSet.new(),
          search_results: [],
          copy_mode: true,
          daily_changes: daily_changes,
          limit_reached: limit_reached
        )
        |> push_event("scroll-to-top", %{})

      _ ->
        socket
        |> clear_flash()
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

  defp send_copy_notifications(results, source_school, selected_ferientage) do
    require Logger

    # Build copy summary for the email
    copy_summary = build_copy_summary(results, source_school, selected_ferientage)

    Logger.info("Sending bulk copy notification email for school: #{source_school.name}")
    Logger.info("Copy summary: #{inspect(copy_summary, pretty: true)}")

    # Send single summary email instead of individual emails
    email = Email.bewegliche_ferientage_bulk_copy_notification(source_school, copy_summary)

    Logger.info("Email created: to=#{inspect(email.to)}, subject=#{email.subject}")

    result = Mailer.deliver!(email)

    Logger.info("Email delivery result: #{inspect(result)}")

    result
  end

  defp build_copy_summary(results, _source_school, selected_ferientage) do
    # Count overall statistics
    {total_success, total_skip, total_error} =
      Enum.reduce(results, {0, 0, 0}, fn {_school_id, school_results}, {s, sk, e} ->
        counts = count_school_results(school_results)
        {s + counts.success, sk + counts.skip, e + counts.error}
      end)

    # Build school results with details
    school_results =
      Enum.map(results, fn {school_id, school_results} ->
        school = Locations.get_location!(school_id)
        counts = count_school_results(school_results)

        status =
          cond do
            counts.error == length(school_results) -> :failed
            counts.success > 0 && (counts.skip > 0 || counts.error > 0) -> :partial
            counts.success > 0 -> :success
            true -> :failed
          end

        %{
          school_id: school_id,
          school_name: school.name,
          school_slug: school.slug,
          status: status,
          success_count: counts.success,
          skip_count: counts.skip,
          error_count: counts.error
        }
      end)
      |> Enum.sort_by(& &1.school_name)

    # Build ferientage details
    ferientage_details =
      selected_ferientage
      |> Enum.map(fn ferientag ->
        %{
          date: ferientag.starts_on,
          memo: ferientag.memo
        }
      end)
      |> Enum.sort_by(& &1.date)

    %{
      ferientage_count: length(selected_ferientage),
      total_schools: map_size(results),
      success_count: total_success,
      skip_count: total_skip,
      error_count: total_error,
      ferientage_details: ferientage_details,
      school_results: school_results
    }
  end

  defp count_school_results(school_results) do
    Enum.reduce(school_results, %{success: 0, skip: 0, error: 0}, fn
      {:success, _}, acc -> %{acc | success: acc.success + 1}
      {:skipped, _, _}, acc -> %{acc | skip: acc.skip + 1}
      {:error, _, _}, acc -> %{acc | error: acc.error + 1}
    end)
  end

  defp has_beweglicher_ferientag_on_date?(ferientage, date) do
    Enum.any?(ferientage, fn ft -> Date.compare(ft.starts_on, date) == :eq end)
  end

  defp calculate_required_changes(socket) do
    # Calculate the maximum number of changes that could be required
    # This is: number of selected ferientage * number of selected schools
    # Note: Some might be skipped if they already exist, but we calculate worst case
    num_ferientage = MapSet.size(socket.assigns.selected_ferientage)
    num_schools = MapSet.size(socket.assigns.selected_schools)

    num_ferientage * num_schools
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
          length(already_has_dates) == length(selected_dates) && selected_dates != []
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

  defp filter_ferientage_by_school_year(ferientage, school_year) do
    [start_year_str, _end_year_str] = String.split(school_year, "/")
    start_year = String.to_integer(start_year_str)

    # School year runs from August 1st to July 31st
    start_date = Date.new!(start_year, 8, 1)
    end_date = Date.new!(start_year + 1, 7, 31)

    Enum.filter(ferientage, fn ft ->
      Date.compare(ft.starts_on, start_date) != :lt &&
        Date.compare(ft.starts_on, end_date) != :gt
    end)
  end
end
