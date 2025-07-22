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

  @impl true
  def mount(%{"slug" => school_slug}, _session, socket) do
    school = Locations.get_school_by_slug!(school_slug)

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
       limit_reached: limit_reached
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

  defp has_beweglicher_ferientag_on_date?(ferientage, date) do
    Enum.any?(ferientage, fn ft -> Date.compare(ft.starts_on, date) == :eq end)
  end
end
