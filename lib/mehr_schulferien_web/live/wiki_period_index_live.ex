defmodule MehrSchulferienWeb.WikiPeriodIndexLive do
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferien.Repo
  alias MehrSchulferien.Periods.Period
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    # Get all federal states in Germany
    federal_states =
      from(l in MehrSchulferien.Locations.Location,
        where: l.is_federal_state == true,
        order_by: l.name
      )
      |> Repo.all()

    # Get vacation types used in the last 12 months
    vacation_types = get_recent_vacation_types()
    
    # Get all years that have periods
    available_years = get_available_years()

    socket =
      socket
      |> assign(:page_title, "Ferientermine verwalten - Wiki")
      |> assign(:css_framework, :tailwind_new)
      |> assign(:federal_states, federal_states)
      |> assign(:vacation_types, vacation_types)
      |> assign(:available_years, available_years)
      |> assign(:selected_federal_state_id, nil)
      |> assign(:selected_vacation_type_id, nil)
      |> assign(:selected_year, Date.utc_today().year)
      |> assign(:periods, [])
      |> assign(:show_filters, true)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> apply_filters(params)
      |> load_periods()

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter_changed", %{"filters" => filters}, socket) do
    params = %{
      "federal_state_id" => filters["federal_state_id"],
      "vacation_type_id" => filters["vacation_type_id"],
      "year" => filters["year"]
    }

    {:noreply, push_patch(socket, to: ~p"/wiki/periods?#{params}")}
  end

  @impl true
  def handle_event("toggle_filters", _params, socket) do
    {:noreply, assign(socket, :show_filters, !socket.assigns.show_filters)}
  end

  defp apply_filters(socket, params) do
    socket
    |> assign(:selected_federal_state_id, parse_id(params["federal_state_id"]))
    |> assign(:selected_vacation_type_id, parse_id(params["vacation_type_id"]))
    |> assign(:selected_year, parse_year(params["year"]))
  end

  defp parse_id(nil), do: nil
  defp parse_id(""), do: nil
  defp parse_id(id) when is_binary(id), do: String.to_integer(id)
  defp parse_id(id), do: id

  defp parse_year(nil), do: Date.utc_today().year
  defp parse_year(""), do: Date.utc_today().year
  defp parse_year(year) when is_binary(year), do: String.to_integer(year)
  defp parse_year(year), do: year

  defp load_periods(socket) do
    query = build_query(socket.assigns)

    periods =
      query
      |> order_by([p], asc: p.starts_on)
      |> preload([:location, :holiday_or_vacation_type])
      |> Repo.all()

    assign(socket, :periods, periods)
  end

  defp build_query(assigns) do
    Period
    |> where([p], p.is_school_vacation == true)
    |> join(:inner, [p], l in assoc(p, :location))
    |> where([p, l], l.is_federal_state == true)
    |> filter_by_federal_state(assigns.selected_federal_state_id)
    |> filter_by_vacation_type(assigns.selected_vacation_type_id)
    |> filter_by_year(assigns.selected_year)
  end

  defp filter_by_federal_state(query, nil), do: query

  defp filter_by_federal_state(query, federal_state_id) do
    where(query, [p, l], p.location_id == ^federal_state_id)
  end

  defp filter_by_vacation_type(query, nil), do: query

  defp filter_by_vacation_type(query, vacation_type_id) do
    where(query, [p, l], p.holiday_or_vacation_type_id == ^vacation_type_id)
  end

  defp filter_by_year(query, nil), do: query

  defp filter_by_year(query, year) do
    start_date = Date.new!(year, 1, 1)
    end_date = Date.new!(year, 12, 31)

    where(
      query,
      [p, l],
      (p.starts_on >= ^start_date and p.starts_on <= ^end_date) or
        (p.ends_on >= ^start_date and p.ends_on <= ^end_date) or
        (p.starts_on <= ^start_date and p.ends_on >= ^end_date)
    )
  end

  defp format_date(date) do
    Calendar.strftime(date, "%d.%m.%Y")
  end

  defp period_duration(period) do
    Date.diff(period.ends_on, period.starts_on) + 1
  end

  defp period_is_in_past?(period) do
    Date.compare(period.ends_on, Date.utc_today()) == :lt
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
      from(vt in MehrSchulferien.Calendars.HolidayOrVacationType,
        where: vt.default_is_school_vacation == true,
        order_by: vt.name
      )
      |> Repo.all()
    else
      # Get the vacation types that match these IDs
      from(vt in MehrSchulferien.Calendars.HolidayOrVacationType,
        where: vt.id in ^vacation_type_ids and vt.default_is_school_vacation == true,
        order_by: vt.name
      )
      |> Repo.all()
    end
  end

  defp get_available_years do
    # Get all unique years from periods
    years = 
      from(p in Period,
        join: l in assoc(p, :location),
        where: p.is_school_vacation == true and l.is_federal_state == true,
        select: fragment("EXTRACT(YEAR FROM ?)::integer", p.starts_on)
      )
      |> Repo.all()
      |> Enum.uniq()
    
    # Ensure current year is included even if no periods exist
    current_year = Date.utc_today().year
    
    years
    |> Enum.concat([current_year])
    |> Enum.uniq()
    |> Enum.sort(:desc)
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
                Ferientermine verwalten
              </.heading>
              <.text class="text-gray-600 dark:text-gray-400 mt-2">
                Bearbeiten Sie Schulferien für Bundesländer
              </.text>
            </div>
            <div class="flex gap-4">
              <button
                phx-click="toggle_filters"
                class="inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-gray-200 text-gray-900 hover:bg-gray-300 h-10 px-4 py-2"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="w-5 h-5 mr-2"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M10.5 6h9.75M10.5 6a1.5 1.5 0 11-3 0m3 0a1.5 1.5 0 10-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-9.75 0h9.75"
                  />
                </svg>
                Filter
              </button>
              <Phoenix.Component.link
                navigate={~p"/wiki/periods/new"}
                class="inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-primary-600 text-white hover:bg-primary-700 h-10 px-4 py-2"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="w-5 h-5 mr-2"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
                </svg>
                Neue Ferien
              </Phoenix.Component.link>
            </div>
          </div>

          <div :if={@show_filters} class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <form phx-change="filter_changed">
              <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <label
                    for="federal_state_id"
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
                  >
                    Bundesland
                  </label>
                  <select
                    name="filters[federal_state_id]"
                    id="federal_state_id"
                    class="w-full rounded-md border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 shadow-sm focus:border-primary-500 focus:ring-primary-500"
                  >
                    <option value="">Alle Bundesländer</option>
                    <option
                      :for={fs <- @federal_states}
                      value={fs.id}
                      selected={fs.id == @selected_federal_state_id}
                    >
                      {fs.name}
                    </option>
                  </select>
                </div>

                <div>
                  <label
                    for="vacation_type_id"
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
                  >
                    Ferienart
                  </label>
                  <select
                    name="filters[vacation_type_id]"
                    id="vacation_type_id"
                    class="w-full rounded-md border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 shadow-sm focus:border-primary-500 focus:ring-primary-500"
                  >
                    <option value="">Alle Ferienarten</option>
                    <option
                      :for={vt <- @vacation_types}
                      value={vt.id}
                      selected={vt.id == @selected_vacation_type_id}
                    >
                      {vt.name}
                    </option>
                  </select>
                </div>

                <div>
                  <label
                    for="year"
                    class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
                  >
                    Jahr
                  </label>
                  <select
                    name="filters[year]"
                    id="year"
                    class="w-full rounded-md border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 shadow-sm focus:border-primary-500 focus:ring-primary-500"
                  >
                    <option :for={year <- @available_years} value={year} selected={year == @selected_year}>
                      {year}
                    </option>
                  </select>
                </div>
              </div>
            </form>
          </div>

          <!-- Mobile-friendly card view for small screens -->
          <div class="block md:hidden space-y-4">
            <div 
              :for={period <- @periods} 
              class="bg-white dark:bg-gray-800 rounded-lg shadow p-4 space-y-2"
            >
              <div class="flex justify-between items-start">
                <div class="flex-1">
                  <div class="font-semibold text-gray-900 dark:text-gray-100">
                    {period.location.name}
                  </div>
                  <div class="text-sm text-gray-600 dark:text-gray-400">
                    {period.holiday_or_vacation_type.name}
                  </div>
                </div>
                <%= if period_is_in_past?(period) do %>
                  <span
                    class="text-gray-400 dark:text-gray-600"
                    title="Vergangene Ferien können nicht bearbeitet werden"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      class="w-5 h-5"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"
                      />
                    </svg>
                  </span>
                <% else %>
                  <Phoenix.Component.link
                    navigate={~p"/wiki/periods/#{period.id}/edit"}
                    class="text-primary-600 hover:text-primary-800 dark:text-primary-400 dark:hover:text-primary-300"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      class="w-5 h-5"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0115.75 21H5.25A2.25 2.25 0 013 18.75V8.25A2.25 2.25 0 015.25 6H10"
                      />
                    </svg>
                  </Phoenix.Component.link>
                <% end %>
              </div>
              <div class="flex flex-wrap gap-x-4 gap-y-1 text-sm">
                <div>
                  <span class="text-gray-500 dark:text-gray-400">Von:</span>
                  <span class="text-gray-900 dark:text-gray-100 ml-1">{format_date(period.starts_on)}</span>
                </div>
                <div>
                  <span class="text-gray-500 dark:text-gray-400">Bis:</span>
                  <span class="text-gray-900 dark:text-gray-100 ml-1">{format_date(period.ends_on)}</span>
                </div>
                <div>
                  <span class="text-gray-500 dark:text-gray-400">Dauer:</span>
                  <span class="text-gray-900 dark:text-gray-100 ml-1">{period_duration(period)} Tage</span>
                </div>
              </div>
            </div>
            
            <div :if={@periods == []} class="bg-white dark:bg-gray-800 rounded-lg shadow p-8 text-center">
              <p class="text-gray-500 dark:text-gray-400">
                Keine Ferientermine gefunden. Passen Sie Ihre Filter an oder fügen Sie neue Termine hinzu.
              </p>
            </div>
          </div>

          <!-- Table view for larger screens -->
          <div class="hidden md:block bg-white dark:bg-gray-800 rounded-lg shadow overflow-hidden">
            <div class="overflow-x-auto">
              <.table>
                <.thead>
                  <.tr>
                    <.th>Bundesland</.th>
                    <.th>Ferienart</.th>
                    <.th>Beginn</.th>
                    <.th>Ende</.th>
                    <.th>Dauer</.th>
                    <.th>Aktionen</.th>
                  </.tr>
                </.thead>
                <.tbody>
                  <.tr :for={period <- @periods} class="hover:bg-gray-50 dark:hover:bg-gray-700">
                    <.td>{period.location.name}</.td>
                    <.td>{period.holiday_or_vacation_type.name}</.td>
                    <.td>{format_date(period.starts_on)}</.td>
                    <.td>{format_date(period.ends_on)}</.td>
                    <.td>{period_duration(period)} Tage</.td>
                    <.td>
                      <div class="flex gap-2">
                        <%= if period_is_in_past?(period) do %>
                          <span
                            class="text-gray-400 dark:text-gray-600"
                            title="Vergangene Ferien können nicht bearbeitet werden"
                          >
                            <svg
                              xmlns="http://www.w3.org/2000/svg"
                              fill="none"
                              viewBox="0 0 24 24"
                              stroke-width="1.5"
                              stroke="currentColor"
                              class="w-5 h-5"
                            >
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"
                              />
                            </svg>
                          </span>
                        <% else %>
                          <Phoenix.Component.link
                            navigate={~p"/wiki/periods/#{period.id}/edit"}
                            class="text-primary-600 hover:text-primary-800 dark:text-primary-400 dark:hover:text-primary-300"
                          >
                            <svg
                              xmlns="http://www.w3.org/2000/svg"
                              fill="none"
                              viewBox="0 0 24 24"
                              stroke-width="1.5"
                              stroke="currentColor"
                              class="w-5 h-5"
                            >
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0115.75 21H5.25A2.25 2.25 0 013 18.75V8.25A2.25 2.25 0 015.25 6H10"
                              />
                            </svg>
                          </Phoenix.Component.link>
                        <% end %>
                      </div>
                    </.td>
                  </.tr>
                  <.tr :if={@periods == []}>
                    <td colspan="6" class="text-center text-gray-500 dark:text-gray-400 py-8 px-6">
                      Keine Ferientermine gefunden. Passen Sie Ihre Filter an oder fügen Sie neue Termine hinzu.
                    </td>
                  </.tr>
                </.tbody>
              </.table>
            </div>
          </div>

          <.card variant="border" class="dark:bg-blue-900 dark:border-blue-700">
            <:content>
              <.text class="text-sm text-gray-700 dark:text-gray-300">
                <strong>Hinweis:</strong>
                Hier werden nur Schulferien angezeigt. Feiertage können nicht über das Wiki bearbeitet werden.
              </.text>
            </:content>
          </.card>
        </.stack>
      </.container>
    </div>
    """
  end
end
