defmodule MehrSchulferienWeb.WikiPeriodNewLive do
  use MehrSchulferienWeb, :live_view

  on_mount {MehrSchulferienWeb.WikiAuth, :require_auth}

  alias MehrSchulferien.{Periods, Calendars, Wiki, Config, Repo, Email, Mailer}
  alias MehrSchulferien.Periods.Period
  import Ecto.Query
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    changeset =
      Periods.change_period(%Period{
        created_by_email_address: "wiki@mehr-schulferien.de",
        display_priority: 5,
        is_school_vacation: true,
        is_listed_below_month: false,
        is_public_holiday: false,
        is_valid_for_everybody: false,
        is_valid_for_students: true
      })

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

    socket =
      socket
      |> assign(:page_title, "Neuen Ferientermin hinzufügen - Wiki")
      |> assign(:changeset, changeset)
      |> assign(:federal_states, federal_states)
      |> assign(:vacation_types, vacation_types)
      |> assign(:daily_changes, daily_changes)
      |> assign(:daily_limit, Config.daily_change_limit())
      |> assign(:limit_reached, limit_reached)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"period" => period_params}, socket) do
    params = prepare_params_for_create(period_params)

    changeset =
      %Period{}
      |> Period.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"period" => period_params}, socket) do
    if socket.assigns.limit_reached do
      {:noreply,
       socket
       |> put_flash(
         :error,
         "Das tägliche Limit von #{socket.assigns.daily_limit} Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
       )}
    else
      save_period(socket, period_params)
    end
  end

  defp save_period(socket, period_params) do
    period_params = prepare_params_for_create(period_params)

    case Periods.create_period(period_params) do
      {:ok, period} ->
        # Increment daily change count
        Wiki.increment_daily_change_count(Date.utc_today())

        # Send email notification
        email_task = fn ->
          Logger.info("Sending email notification for period creation")

          result =
            Email.period_created_notification(period)
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
         |> put_flash(:info, "Ferientermin wurde erfolgreich erstellt.")
         |> redirect(to: ~p"/wiki/periods")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp prepare_params_for_create(params) do
    # Ensure all required fields are present
    params
    |> Map.put("created_by_email_address", "wiki@mehr-schulferien.de")
    |> Map.put("display_priority", "5")
    |> Map.put("is_school_vacation", "true")
    |> Map.put("is_listed_below_month", "false")
    |> Map.put("is_public_holiday", "false")
    |> Map.put("is_valid_for_everybody", "false")
    |> Map.put("is_valid_for_students", "true")
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 dark:bg-gray-900 py-8">
      <.container>
        <.stack spacing="6">
          <div class="flex justify-between items-center">
            <div>
              <.heading level={1} class="text-gray-900 dark:text-gray-100">
                Neuen Ferientermin hinzufügen
              </.heading>
              <.text class="text-gray-600 dark:text-gray-400 mt-2">
                Fügen Sie neue Schulferien für ein Bundesland hinzu
              </.text>
            </div>
            <Phoenix.Component.link
              navigate={~p"/wiki/periods"}
              class="text-primary-600 hover:text-primary-800 dark:text-primary-400 dark:hover:text-primary-300"
            >
              ← Zurück zur Übersicht
            </Phoenix.Component.link>
          </div>

          <div
            :if={@limit_reached}
            class="bg-red-50 dark:bg-red-900 border border-red-200 dark:border-red-700 rounded-lg p-4"
          >
            <.text class="text-red-800 dark:text-red-200">
              <strong>Achtung:</strong>
              Das tägliche Limit von {@daily_limit} Änderungen wurde erreicht.
              Sie können diese Seite ansehen, aber keine neuen Termine hinzufügen.
            </.text>
          </div>

          <.card class="max-w-2xl mx-auto w-full dark:bg-gray-800">
            <:content>
              <.heading level={3} class="mb-4 text-gray-900 dark:text-gray-100">
                Feriendaten eingeben
              </.heading>

              <form phx-change="validate" phx-submit="save" class="space-y-6">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label
                      for="period_location_id"
                      class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                    >
                      Bundesland <span class="text-red-500">*</span>
                    </label>
                    <select
                      id="period_location_id"
                      name="period[location_id]"
                      class="w-full rounded-md border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 shadow-sm focus:border-primary-500 focus:ring-primary-500"
                      disabled={@limit_reached}
                      required
                    >
                      <option value="">Bitte wählen</option>
                      <%= for fs <- @federal_states do %>
                        <option value={fs.id}>
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
                      Ferienart <span class="text-red-500">*</span>
                    </label>
                    <select
                      id="period_holiday_or_vacation_type_id"
                      name="period[holiday_or_vacation_type_id]"
                      class="w-full rounded-md border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 shadow-sm focus:border-primary-500 focus:ring-primary-500"
                      disabled={@limit_reached}
                      required
                    >
                      <option value="">Bitte wählen</option>
                      <%= for vt <- @vacation_types do %>
                        <option value={vt.id}>
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
                      Beginn <span class="text-red-500">*</span>
                    </label>
                    <input
                      type="date"
                      id="period_starts_on"
                      name="period[starts_on]"
                      class="w-full rounded-md border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 shadow-sm focus:border-primary-500 focus:ring-primary-500"
                      disabled={@limit_reached}
                      required
                    />
                  </div>

                  <div>
                    <label
                      for="period_ends_on"
                      class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
                    >
                      Ende <span class="text-red-500">*</span>
                    </label>
                    <input
                      type="date"
                      id="period_ends_on"
                      name="period[ends_on]"
                      class="w-full rounded-md border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 shadow-sm focus:border-primary-500 focus:ring-primary-500"
                      disabled={@limit_reached}
                      required
                    />
                    <%= if @changeset.errors[:starts_on] || @changeset.errors[:ends_on] do %>
                      <p class="mt-1 text-sm text-red-600 dark:text-red-400">
                        <%= if @changeset.errors[:starts_on] do %>
                          {elem(@changeset.errors[:starts_on], 0)}
                        <% end %>
                      </p>
                    <% end %>
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
                    rows="3"
                    class="w-full rounded-md border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 shadow-sm focus:border-primary-500 focus:ring-primary-500"
                    disabled={@limit_reached}
                    placeholder="Zusätzliche Informationen zu diesem Ferientermin"
                  ></textarea>
                </div>

                <div>
                  <.button type="submit" disabled={@limit_reached}>
                    Ferientermin erstellen
                  </.button>
                </div>
              </form>
            </:content>
          </.card>

          <.card
            variant="border"
            class="max-w-2xl mx-auto w-full dark:bg-blue-900 dark:border-blue-700"
          >
            <:content>
              <.heading level={4} class="text-gray-900 dark:text-gray-100">
                Hinweise
              </.heading>
              <ul class="mt-2 space-y-1 list-disc ml-5 text-gray-700 dark:text-gray-300">
                <li>Stellen Sie sicher, dass die Daten korrekt sind</li>
                <li>Überprüfen Sie vorher, ob der Termin bereits existiert</li>
                <li>Änderungen heute: {@daily_changes} / {@daily_limit}</li>
              </ul>
            </:content>
          </.card>
        </.stack>
      </.container>
    </div>
    """
  end
end
