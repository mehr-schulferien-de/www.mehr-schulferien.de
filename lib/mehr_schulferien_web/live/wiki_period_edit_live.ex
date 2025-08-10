defmodule MehrSchulferienWeb.WikiPeriodEditLive do
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferien.{Periods, Locations, Calendars, Wiki, Config, Repo, Email, Mailer}
  alias MehrSchulferien.Periods.Period
  import Ecto.Query
  require Logger

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    period = get_period_with_preloads(id)

    if period do
      changeset = Periods.change_period(period)
      versions = get_period_versions(period)

      federal_states =
        from(l in MehrSchulferien.Locations.Location,
          where: l.is_federal_state == true,
          order_by: l.name
        )
        |> Repo.all()

      vacation_types = get_recent_vacation_types()

      # Check daily limit
      today = Date.utc_today()
      daily_changes = Wiki.get_daily_change_count(today)
      limit_reached = daily_changes >= Config.daily_change_limit()

      # Get client IP during mount
      client_ip =
        case get_connect_info(socket, :peer_data) do
          %{address: {a, b, c, d}} -> "#{a}.#{b}.#{c}.#{d}"
          # Default to localhost for tests
          _ -> "127.0.0.1"
        end

      # Check if period is in the past
      is_past_period = period_is_in_past?(period)

      socket =
        socket
        |> assign(:page_title, "Ferientermin bearbeiten - Wiki")
        |> assign(:css_framework, :tailwind_new)
        |> assign(:period, period)
        |> assign(:changeset, changeset)
        |> assign(:federal_states, federal_states)
        |> assign(:vacation_types, vacation_types)
        |> assign(:versions, versions)
        |> assign(:display_versions, Enum.take(versions, 5))
        |> assign(:show_all_versions, false)
        |> assign(:daily_changes, daily_changes)
        |> assign(:daily_limit, Config.daily_change_limit())
        |> assign(:limit_reached, limit_reached)
        |> assign(:show_delete_confirm, false)
        |> assign(:show_delete_modal, false)
        |> assign(:affected_schools_count, 0)
        |> assign(:client_ip, client_ip)
        |> assign(:is_past_period, is_past_period)

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Ferientermin nicht gefunden")
       |> redirect(to: ~p"/wiki/periods")}
    end
  end

  @impl true
  def handle_event("validate", %{"period" => period_params}, socket) do
    changeset =
      socket.assigns.period
      |> Period.changeset(period_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"period" => period_params}, socket) do
    cond do
      socket.assigns.is_past_period ->
        {:noreply,
         socket
         |> put_flash(:error, "Vergangene Ferientermine können nicht bearbeitet werden.")}

      socket.assigns.limit_reached ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Das tägliche Limit von #{socket.assigns.daily_limit} Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
         )}

      true ->
        save_period(socket, period_params)
    end
  end

  @impl true
  def handle_event("toggle_versions", _params, socket) do
    {:noreply, assign(socket, :show_all_versions, !socket.assigns.show_all_versions)}
  end

  @impl true
  def handle_event("rollback", params, socket) do
    # Handle both "version-id" and "version_id" keys
    version_id = params["version-id"] || params["version_id"]

    if socket.assigns.limit_reached do
      {:noreply,
       socket
       |> put_flash(
         :error,
         "Das tägliche Limit von #{socket.assigns.daily_limit} Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
       )}
    else
      rollback_to_version(socket, version_id)
    end
  end

  @impl true
  def handle_event("toggle_delete_confirm", _params, socket) do
    {:noreply, assign(socket, :show_delete_confirm, !socket.assigns.show_delete_confirm)}
  end

  @impl true
  def handle_event("show_delete_modal", _params, socket) do
    if socket.assigns.is_past_period do
      {:noreply,
       socket
       |> put_flash(:error, "Vergangene Ferientermine können nicht gelöscht werden.")}
    else
      # Count affected schools when showing the modal
      affected_count = count_affected_schools(socket.assigns.period)

      {:noreply,
       socket
       |> assign(:show_delete_modal, true)
       |> assign(:affected_schools_count, affected_count)}
    end
  end

  @impl true
  def handle_event("hide_delete_modal", _params, socket) do
    {:noreply, assign(socket, :show_delete_modal, false)}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    if socket.assigns.limit_reached do
      {:noreply,
       socket
       |> put_flash(
         :error,
         "Das tägliche Limit von #{socket.assigns.daily_limit} Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
       )}
    else
      delete_period(socket)
    end
  end

  defp get_period_with_preloads(id) do
    Period
    |> preload([:location, :holiday_or_vacation_type])
    |> Repo.get(id)
  end

  defp get_period_versions(period) do
    PaperTrail.get_versions(period)
    |> Enum.sort_by(&{&1.inserted_at, &1.id}, :desc)
  end

  defp is_current_version?(version, versions) do
    # The first version in the list (most recent) is the current state
    case versions do
      [current | _] -> version.id == current.id
      _ -> false
    end
  end

  defp count_affected_schools(period) do
    # Count all schools within this federal state's hierarchy
    # Schools can be under: Federal State → County → City → School
    federal_state_id = period.location_id

    # Get all counties in this federal state
    county_ids =
      from(l in MehrSchulferien.Locations.Location,
        where: l.parent_location_id == ^federal_state_id and l.is_county == true,
        select: l.id
      )
      |> Repo.all()

    # Get all cities in these counties
    city_ids =
      from(l in MehrSchulferien.Locations.Location,
        where: l.parent_location_id in ^county_ids and l.is_city == true,
        select: l.id
      )
      |> Repo.all()

    # Count schools that are direct children of cities
    from(l in MehrSchulferien.Locations.Location,
      where: l.parent_location_id in ^city_ids and l.is_school == true,
      select: count(l.id)
    )
    |> Repo.one() || 0
  end

  defp save_period(socket, period_params) do
    changeset = Period.changeset(socket.assigns.period, period_params)

    case PaperTrail.update(changeset, meta: %{ip_address: socket.assigns.client_ip}) do
      {:ok, result} ->
        # Extract model and version (version might be nil if no changes)
        updated_period = Map.get(result, :model)
        version = Map.get(result, :version)

        # Increment daily change count if there was a version created
        if version do
          Wiki.increment_daily_change_count(Date.utc_today())

          # Send email notification
          email_task = fn ->
            Logger.info("Sending email notification for period update")
            changes = gather_changes(version)

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

        # Reload period with updated data and versions
        updated_period = get_period_with_preloads(updated_period.id)
        updated_versions = get_period_versions(updated_period)

        # Update daily changes count
        new_daily_changes =
          if version, do: socket.assigns.daily_changes + 1, else: socket.assigns.daily_changes

        {:noreply,
         socket
         |> put_flash(:info, "Ferientermin wurde erfolgreich aktualisiert.")
         |> assign(:period, updated_period)
         |> assign(:versions, updated_versions)
         |> assign(:display_versions, Enum.take(updated_versions, 5))
         |> assign(:changeset, Periods.change_period(updated_period))
         |> assign(:daily_changes, new_daily_changes)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp rollback_to_version(socket, version_id) do
    case Wiki.rollback_to_version(socket.assigns.period, version_id, socket.assigns.client_ip) do
      {:ok, result} ->
        Wiki.increment_daily_change_count(Date.utc_today())

        # Extract the model from the result (same structure as PaperTrail.update)
        updated_period = Map.get(result, :model)

        # Reload period with updated data and versions
        reloaded_period = get_period_with_preloads(updated_period.id)
        updated_versions = get_period_versions(reloaded_period)

        # Update daily changes count
        new_daily_changes = socket.assigns.daily_changes + 1

        {:noreply,
         socket
         |> put_flash(:info, "Erfolgreich zur ausgewählten Version zurückgekehrt.")
         |> assign(:period, reloaded_period)
         |> assign(:versions, updated_versions)
         |> assign(:display_versions, Enum.take(updated_versions, 5))
         |> assign(:changeset, Periods.change_period(reloaded_period))
         |> assign(:daily_changes, new_daily_changes)}

      {:error, :already_at_version} ->
        {:noreply,
         socket
         |> put_flash(:info, "Die Daten entsprechen bereits dieser Version.")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Fehler beim Zurückkehren zur ausgewählten Version.")}
    end
  end

  defp delete_period(socket) do
    case Periods.delete_period(socket.assigns.period) do
      {:ok, _period} ->
        Wiki.increment_daily_change_count(Date.utc_today())

        # Send email notification
        email_task = fn ->
          Logger.info("Sending email notification for period deletion")

          result =
            Email.period_deleted_notification(socket.assigns.period)
            |> Mailer.deliver()

          Logger.info("Email send result: #{inspect(result)}")
        end

        # Run synchronously in test environment to avoid connection ownership issues
        if Application.get_env(:mehr_schulferien, :env) == :test do
          email_task.()
        else
          Task.start(email_task)
        end

        {:noreply,
         socket
         |> put_flash(:info, "Ferientermin wurde erfolgreich gelöscht.")
         |> redirect(to: ~p"/wiki/periods")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Fehler beim Löschen des Ferientermins.")}
    end
  end

  defp format_date(date) do
    Calendar.strftime(date, "%d.%m.%Y")
  end

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%d.%m.%Y %H:%M")
  end

  defp version_field_name("starts_on"), do: "Beginn"
  defp version_field_name("ends_on"), do: "Ende"
  defp version_field_name("location_id"), do: "Bundesland"
  defp version_field_name("holiday_or_vacation_type_id"), do: "Ferienart"
  defp version_field_name("memo"), do: "Notiz"
  defp version_field_name(field), do: field

  defp format_version_value("starts_on", value) when not is_nil(value) and value != "" do
    case value do
      %Date{} = date ->
        format_date(date)

      date_string when is_binary(date_string) ->
        case Date.from_iso8601(date_string) do
          {:ok, date} -> format_date(date)
          _ -> date_string
        end

      _ ->
        ""
    end
  end

  defp format_version_value("ends_on", value) when not is_nil(value) and value != "" do
    case value do
      %Date{} = date ->
        format_date(date)

      date_string when is_binary(date_string) ->
        case Date.from_iso8601(date_string) do
          {:ok, date} -> format_date(date)
          _ -> date_string
        end

      _ ->
        ""
    end
  end

  defp format_version_value("starts_on", _), do: ""
  defp format_version_value("ends_on", _), do: ""

  defp format_version_value("location_id", id) when id != nil and id != "" do
    case Locations.get_location(id) do
      nil -> "ID: #{id}"
      location -> location.name
    end
  end

  defp format_version_value("location_id", _), do: ""

  defp format_version_value("holiday_or_vacation_type_id", id) when id != nil and id != "" do
    try do
      type = Calendars.get_holiday_or_vacation_type!(id)
      type.name
    rescue
      Ecto.NoResultsError -> "ID: #{id}"
    end
  end

  defp format_version_value("holiday_or_vacation_type_id", _), do: ""

  defp format_version_value(_, value), do: to_string(value)

  defp gather_changes(version) do
    # Get the previous values for the period
    old_values = get_previous_values(version)

    version.item_changes
    |> Enum.map(fn {field, new_value} ->
      field_str = to_string(field)
      field_atom = String.to_atom(field_str)
      old_value = Map.get(old_values, field_atom, "")

      {version_field_name(field_str),
       {format_version_value(field_str, old_value), format_version_value(field_str, new_value)}}
    end)
    |> Enum.into(%{})
  end

  defp get_previous_values(current_version) do
    # Get all versions for this period
    versions =
      PaperTrail.Version
      |> where([v], v.item_type == "Period" and v.item_id == ^current_version.item_id)
      |> order_by([v], asc: v.id)
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
      # No previous version. For the first version, we can try to infer the old values
      # by looking at what changed. If a field changed, the old value was whatever
      # was there before the change.

      # Get the period record to see its original state
      _period = Repo.get!(Period, current_version.item_id)

      # For the first version, we need to "undo" the changes to get the original values
      changes = current_version.item_changes || %{}

      # Create a map of original values for fields that were changed
      changes
      |> Enum.reduce(%{}, fn {field_str, _new_value}, acc ->
        field_atom = if is_atom(field_str), do: field_str, else: String.to_atom(field_str)

        # For the first version of a field, we can't know the original value
        # unless we have additional context. PaperTrail only records changes,
        # not the original state.
        Map.put(acc, field_atom, nil)
      end)
    end
  end

  defp get_recent_vacation_types do
    # Get vacation types used in periods from the last 12 months
    twelve_months_ago = Date.utc_today() |> Date.add(-365)

    vacation_type_ids =
      from(p in Period,
        join: l in assoc(p, :location),
        where: p.is_school_vacation == true and l.is_federal_state == true,
        where: p.starts_on >= ^twelve_months_ago or p.ends_on >= ^twelve_months_ago,
        select: p.holiday_or_vacation_type_id,
        distinct: true
      )
      |> Repo.all()

    # If no vacation types found in recent periods, get all school vacation types
    if vacation_type_ids == [] do
      from(vt in Calendars.HolidayOrVacationType,
        where: vt.default_is_school_vacation == true,
        order_by: vt.name
      )
      |> Repo.all()
    else
      # Get the vacation types that match these IDs
      from(vt in Calendars.HolidayOrVacationType,
        where: vt.id in ^vacation_type_ids and vt.default_is_school_vacation == true,
        order_by: vt.name
      )
      |> Repo.all()
    end
  end

  defp period_is_in_past?(period) do
    Date.compare(period.ends_on, Date.utc_today()) == :lt
  end

  defp get_old_value_for_field(version, field_str) do
    # This function tries to reconstruct what the old value was before this version
    # by looking at the version history

    field_atom = String.to_atom(field_str)

    # Get all versions for this period in chronological order
    all_versions =
      PaperTrail.Version
      |> where([v], v.item_type == "Period" and v.item_id == ^version.item_id)
      |> order_by([v], asc: v.id)
      |> Repo.all()

    # Find the index of the current version
    current_index = Enum.find_index(all_versions, fn v -> v.id == version.id end)

    if current_index == nil do
      nil
    else
      # Get all versions before the current one
      versions_before = Enum.take(all_versions, current_index)

      if versions_before == [] do
        # This is the first version - we can't determine the original value
        # without looking at the period record itself
        nil
      else
        # Look backwards through versions to find the most recent change to this field
        versions_before
        |> Enum.reverse()
        |> Enum.find_value(nil, fn v ->
          changes = v.item_changes || %{}

          # Convert keys to atoms if needed
          atomized_changes =
            changes
            |> Enum.map(fn {k, v} ->
              {if(is_atom(k), do: k, else: String.to_atom(k)), v}
            end)
            |> Enum.into(%{})

          # If this version changed the field, that's the value we want
          case Map.get(atomized_changes, field_atom) do
            # Continue looking
            nil -> nil
            value -> {:found, value}
          end
        end)
        |> case do
          {:found, value} -> value
          # Field was never changed before, so original value is unknown
          nil -> nil
        end
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Flash messages -->
      <%= if Phoenix.Flash.get(@flash, :info) do %>
        <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4 mb-6">
          <p class="text-green-800 dark:text-green-300">
            {Phoenix.Flash.get(@flash, :info)}
          </p>
        </div>
      <% end %>

      <%= if Phoenix.Flash.get(@flash, :error) do %>
        <div class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mb-6">
          <p class="text-red-800 dark:text-red-300">
            {Phoenix.Flash.get(@flash, :error)}
          </p>
        </div>
      <% end %>
      
    <!-- Header -->
      <div class="flex justify-between items-center mb-8">
        <div>
          <h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100">
            Ferientermin bearbeiten
          </h1>
          <p class="text-gray-600 dark:text-gray-400 mt-2">
            {format_date(@period.starts_on)} - {format_date(@period.ends_on)}
          </p>
        </div>
        <Phoenix.Component.link
          navigate={~p"/wiki/periods"}
          class="text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300"
        >
          ← Zurück zur Übersicht
        </Phoenix.Component.link>
      </div>
      
    <!-- Warning messages -->
      <div
        :if={@limit_reached}
        class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-700 rounded-lg p-4 mb-6"
      >
        <p class="text-red-800 dark:text-red-200">
          <strong>Achtung:</strong> Das tägliche Limit von {@daily_limit} Änderungen wurde erreicht.
          Sie können diese Seite ansehen, aber keine Änderungen vornehmen.
        </p>
      </div>

      <div
        :if={@is_past_period}
        class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-700 rounded-lg p-4 mb-6"
      >
        <p class="text-yellow-800 dark:text-yellow-200">
          <strong>Hinweis:</strong>
          Dieser Ferientermin liegt in der Vergangenheit und kann nicht mehr bearbeitet oder gelöscht werden.
          Sie können diese Seite nur zur Ansicht verwenden.
        </p>
      </div>
      
    <!-- Main content grid -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Main form column -->
        <div class="lg:col-span-2">
          <div class="bg-white dark:bg-gray-800 shadow-sm rounded-lg p-6">
            <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100 mb-6">
              Feriendaten bearbeiten
            </h2>

            <form phx-change="validate" phx-submit="save" class="space-y-4">
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label
                    for="period_location_id"
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                  >
                    Bundesland *
                  </label>
                  <select
                    id="period_location_id"
                    name="period[location_id]"
                    class="mt-1 block w-full rounded-md border-2 border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-3 py-2 text-gray-900 dark:text-gray-100"
                    disabled={@limit_reached or @is_past_period}
                    required
                  >
                    <%= for fs <- @federal_states do %>
                      <option
                        value={fs.id}
                        selected={fs.id == Ecto.Changeset.get_field(@changeset, :location_id)}
                      >
                        {fs.name}
                      </option>
                    <% end %>
                  </select>
                </div>

                <div>
                  <label
                    for="period_holiday_or_vacation_type_id"
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                  >
                    Ferienart *
                  </label>
                  <select
                    id="period_holiday_or_vacation_type_id"
                    name="period[holiday_or_vacation_type_id]"
                    class="mt-1 block w-full rounded-md border-2 border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-3 py-2 text-gray-900 dark:text-gray-100"
                    disabled={@limit_reached or @is_past_period}
                    required
                  >
                    <%= for vt <- @vacation_types do %>
                      <option
                        value={vt.id}
                        selected={
                          vt.id ==
                            Ecto.Changeset.get_field(@changeset, :holiday_or_vacation_type_id)
                        }
                      >
                        {vt.name}
                      </option>
                    <% end %>
                  </select>
                </div>

                <div>
                  <label
                    for="period_starts_on"
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                  >
                    Beginn *
                  </label>
                  <input
                    type="date"
                    id="period_starts_on"
                    name="period[starts_on]"
                    value={Ecto.Changeset.get_field(@changeset, :starts_on)}
                    class="mt-1 block w-full rounded-md border-2 border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-3 py-2 text-gray-900 dark:text-gray-100"
                    disabled={@limit_reached or @is_past_period}
                    required
                  />
                </div>

                <div>
                  <label
                    for="period_ends_on"
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                  >
                    Ende *
                  </label>
                  <input
                    type="date"
                    id="period_ends_on"
                    name="period[ends_on]"
                    value={Ecto.Changeset.get_field(@changeset, :ends_on)}
                    class="mt-1 block w-full rounded-md border-2 border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-3 py-2 text-gray-900 dark:text-gray-100"
                    disabled={@limit_reached or @is_past_period}
                    required
                  />
                </div>
              </div>

              <div>
                <label
                  for="period_memo"
                  class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                >
                  Notiz (optional)
                </label>
                <textarea
                  id="period_memo"
                  name="period[memo]"
                  rows="4"
                  class="mt-1 block w-full rounded-md border-2 border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-3 py-2 placeholder-gray-400 dark:placeholder-gray-500 text-gray-900 dark:text-gray-100"
                  disabled={@limit_reached or @is_past_period}
                  placeholder="Zusätzliche Informationen zu diesem Ferientermin..."
                >{Ecto.Changeset.get_field(@changeset, :memo) || ""}</textarea>
                <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                  Hier können Sie zusätzliche Informationen oder Besonderheiten zu diesem Ferientermin notieren.
                </p>
              </div>

              <div class="pt-4 flex justify-between">
                <button
                  type="submit"
                  disabled={@limit_reached or @is_past_period}
                  class="flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-white dark:focus:ring-offset-gray-800 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Änderungen speichern
                </button>

                <button
                  type="button"
                  phx-click="show_delete_modal"
                  disabled={@limit_reached or @is_past_period}
                  class="flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-white dark:focus:ring-offset-gray-800 focus:ring-red-500 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Löschen
                </button>
              </div>
            </form>
          </div>
        </div>
        
    <!-- Sidebar column -->
        <div class="space-y-6">
          <!-- Daily limit info -->
          <div class="bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-6">
            <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-3">
              Tageslimit
            </h3>
            <div class="space-y-2 text-sm">
              <div class="flex items-center justify-between">
                <span class="text-gray-600 dark:text-gray-400">Heutige Änderungen:</span>
                <span class="font-semibold text-gray-900 dark:text-gray-100">
                  {@daily_changes} / {@daily_limit}
                </span>
              </div>
              <div class="mt-2">
                <div class="bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                  <div
                    class={"h-2 rounded-full #{if @limit_reached, do: "bg-red-600", else: "bg-green-600"}"}
                    style={"width: #{min(@daily_changes / @daily_limit * 100, 100)}%"}
                  >
                  </div>
                </div>
              </div>
              <%= if @limit_reached do %>
                <p class="text-red-600 text-sm mt-2">
                  Das Tageslimit wurde erreicht. Bitte versuchen Sie es morgen erneut.
                </p>
              <% end %>
            </div>
          </div>
          
    <!-- Version history -->
          <div class="bg-white dark:bg-gray-800 shadow-sm rounded-lg p-6">
            <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-4">
              Änderungshistorie
            </h3>

            <div class="space-y-3">
              <%= for {version, index} <- Enum.with_index(if(@show_all_versions, do: @versions, else: @display_versions)) do %>
                <% is_current = is_current_version?(version, @versions) %>
                <div class={[
                  "relative rounded-lg p-3 transition-colors",
                  if(is_current,
                    do:
                      "bg-blue-50 dark:bg-blue-900/20 border-2 border-blue-300 dark:border-blue-700",
                    else: "bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600"
                  )
                ]}>
                  <div class="flex items-start justify-between mb-2">
                    <div>
                      <div class="text-xs text-gray-600 dark:text-gray-400">
                        {format_datetime(version.inserted_at)}
                      </div>
                      <%= if is_current do %>
                        <span class="inline-block mt-1 px-2 py-0.5 text-xs font-semibold bg-blue-100 dark:bg-blue-800 text-blue-800 dark:text-blue-200 rounded">
                          Aktuell
                        </span>
                      <% else %>
                        <span class="inline-block mt-1 text-xs text-gray-500 dark:text-gray-400">
                          v{length(@versions) - index}
                        </span>
                      <% end %>
                    </div>
                    <%= if version.meta && version.meta["rollback_to"] do %>
                      <span class="text-xs text-gray-500 dark:text-gray-400 italic">
                        Rollback
                      </span>
                    <% end %>
                  </div>

                  <%= if version.item_changes && map_size(version.item_changes) > 0 do %>
                    <div class="space-y-1 mt-2">
                      <%= for {field, new_value} <- version.item_changes do %>
                        <% field_str = to_string(field) %>
                        <% old_value = get_old_value_for_field(version, field_str) %>
                        <div class="text-xs">
                          <span class="font-medium text-gray-600 dark:text-gray-300">
                            {version_field_name(field_str)}:
                          </span>
                          <div class="flex items-center gap-2 mt-0.5">
                            <span class="text-red-600 dark:text-red-400 line-through">
                              <%= if old_value != nil && old_value != "" do %>
                                {format_version_value(field_str, old_value)}
                              <% else %>
                                (leer)
                              <% end %>
                            </span>
                            <span class="text-gray-400">→</span>
                            <span class="text-green-600 dark:text-green-400">
                              {format_version_value(field_str, new_value)}
                            </span>
                          </div>
                        </div>
                      <% end %>
                    </div>
                  <% else %>
                    <div class="text-xs text-gray-500 dark:text-gray-400 italic mt-2">
                      Keine Änderungen
                    </div>
                  <% end %>

                  <%= unless is_current do %>
                    <div class="mt-2">
                      <button
                        phx-click="rollback"
                        phx-value-version-id={version.id}
                        disabled={@limit_reached or @is_past_period}
                        class="text-xs text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        ← Zurücksetzen
                      </button>
                    </div>
                  <% end %>
                </div>
              <% end %>

              <div :if={length(@versions) > 5}>
                <button
                  phx-click="toggle_versions"
                  class="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300"
                >
                  {if @show_all_versions,
                    do: "Weniger anzeigen",
                    else: "Alle #{length(@versions)} Versionen anzeigen"}
                </button>
              </div>

              <%= if @versions == [] do %>
                <div class="text-center py-4">
                  <svg
                    class="mx-auto h-10 w-10 text-gray-400 dark:text-gray-500 mb-2"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  <p class="text-sm text-gray-500 dark:text-gray-400">
                    Noch keine Änderungen
                  </p>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
      <!-- Delete Confirmation Modal -->
      <div
        :if={@show_delete_modal}
        class="fixed inset-0 z-50 overflow-y-auto"
        aria-labelledby="modal-title"
        role="dialog"
        aria-modal="true"
      >
        <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
          <!-- Background overlay -->
          <div
            class="fixed inset-0 bg-gray-500 bg-opacity-75 dark:bg-gray-900 dark:bg-opacity-75 transition-opacity"
            aria-hidden="true"
            phx-click="hide_delete_modal"
          >
          </div>
          
    <!-- This element is to trick the browser into centering the modal contents. -->
          <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">
            &#8203;
          </span>
          
    <!-- Modal panel -->
          <div class="inline-block align-bottom bg-white dark:bg-gray-800 rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
            <div class="bg-white dark:bg-gray-800 px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
              <div class="sm:flex sm:items-start">
                <div class="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-red-100 dark:bg-red-900/20 sm:mx-0 sm:h-10 sm:w-10">
                  <svg
                    class="h-6 w-6 text-red-600 dark:text-red-400"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"
                    />
                  </svg>
                </div>
                <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                  <h3
                    class="text-lg leading-6 font-medium text-gray-900 dark:text-gray-100"
                    id="modal-title"
                  >
                    Ferientermin löschen
                  </h3>
                  <div class="mt-2">
                    <p class="text-sm text-gray-500 dark:text-gray-400">
                      Sind Sie sicher, dass Sie diesen Ferientermin löschen möchten?
                    </p>
                    <div class="mt-3 space-y-1 text-sm">
                      <p class="text-gray-700 dark:text-gray-300">
                        <strong>Zeitraum:</strong> {format_date(@period.starts_on)} - {format_date(
                          @period.ends_on
                        )}
                      </p>
                      <p class="text-gray-700 dark:text-gray-300">
                        <strong>Bundesland:</strong> {@period.location.name}
                      </p>
                      <p class="text-gray-700 dark:text-gray-300">
                        <strong>Ferienart:</strong> {@period.holiday_or_vacation_type.name}
                      </p>
                    </div>
                    <div class="mt-4 p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-700 rounded-md">
                      <p class="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                        ⚠️ Diese Aktion betrifft <strong>{@affected_schools_count} Schulen</strong>
                        in diesem Bundesland.
                      </p>
                      <p class="text-sm text-yellow-700 dark:text-yellow-300 mt-1">
                        Die Ferien werden für alle betroffenen Schulen gelöscht.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="bg-gray-50 dark:bg-gray-700/50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
              <button
                type="button"
                phx-click="delete"
                class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm"
              >
                Endgültig löschen
              </button>
              <button
                type="button"
                phx-click="hide_delete_modal"
                class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 dark:border-gray-600 shadow-sm px-4 py-2 bg-white dark:bg-gray-800 text-base font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
              >
                Abbrechen
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
