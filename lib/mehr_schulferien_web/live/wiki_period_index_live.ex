defmodule MehrSchulferienWeb.WikiPeriodIndexLive do
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferien.Repo
  alias MehrSchulferien.Periods.Period
  alias MehrSchulferienWeb.LocationTrackingHelpers
  import Ecto.Query

  @impl true
  def mount(_params, session, socket) do
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

    # Extract federal states from cookies, or select all if none found
    selected_federal_state_ids = get_preselected_federal_states(session, federal_states)
    selected_vacation_type_ids = Enum.map(vacation_types, & &1.id)

    # Preselect current and next year
    current_year = Date.utc_today().year
    next_year = current_year + 1

    selected_years =
      [current_year, next_year]
      |> Enum.filter(&(&1 in available_years))

    socket =
      socket
      |> assign(:page_title, "Ferientermine verwalten - Wiki")
      |> assign(:css_framework, :tailwind_new)
      |> assign(:federal_states, federal_states)
      |> assign(:vacation_types, vacation_types)
      |> assign(:available_years, available_years)
      |> assign(:selected_federal_state_ids, selected_federal_state_ids)
      |> assign(:selected_vacation_type_ids, selected_vacation_type_ids)
      |> assign(:selected_years, selected_years)
      |> assign(:periods, [])
      |> assign(:federal_state_counts, %{})
      |> assign(:vacation_type_counts, %{})
      |> assign(:year_counts, %{})
      |> assign(:show_filters, true)
      |> assign(:sort_by, [:federal_state, :vacation_type, :starts_on])
      |> assign(:sort_direction, :asc)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      if map_size(params) == 0 do
        # No params - use the preselected values from mount
        socket
        |> load_periods()
      else
        # Apply filters from params
        socket
        |> apply_filters(params)
        |> load_periods()
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter_changed", params, socket) do
    socket =
      socket
      |> update_filters(params)
      |> load_periods()

    {:noreply, socket}
  end

  @impl true
  def handle_event("sort_by", %{"field" => field}, socket) do
    field_atom = String.to_existing_atom(field)

    {sort_by, sort_direction} =
      if socket.assigns.sort_by == [field_atom] do
        # If clicking the same field, toggle direction
        direction = if socket.assigns.sort_direction == :asc, do: :desc, else: :asc
        {[field_atom], direction}
      else
        # New field, use ascending
        {[field_atom], :asc}
      end

    socket =
      socket
      |> assign(:sort_by, sort_by)
      |> assign(:sort_direction, sort_direction)
      |> load_periods()

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_filters", _params, socket) do
    {:noreply, assign(socket, :show_filters, !socket.assigns.show_filters)}
  end

  @impl true
  def handle_event("select_all_federal_states", _params, socket) do
    all_ids = Enum.map(socket.assigns.federal_states, & &1.id)

    socket =
      socket
      |> assign(:selected_federal_state_ids, all_ids)
      |> load_periods()

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_none_federal_states", _params, socket) do
    socket =
      socket
      |> assign(:selected_federal_state_ids, [])
      |> load_periods()

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_all_vacation_types", _params, socket) do
    all_ids = Enum.map(socket.assigns.vacation_types, & &1.id)

    socket =
      socket
      |> assign(:selected_vacation_type_ids, all_ids)
      |> load_periods()

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_none_vacation_types", _params, socket) do
    socket =
      socket
      |> assign(:selected_vacation_type_ids, [])
      |> load_periods()

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_all_years", _params, socket) do
    socket =
      socket
      |> assign(:selected_years, socket.assigns.available_years)
      |> load_periods()

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_none_years", _params, socket) do
    socket =
      socket
      |> assign(:selected_years, [])
      |> load_periods()

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_only_federal_state", %{"id" => id}, socket) do
    id = String.to_integer(id)

    socket =
      socket
      |> assign(:selected_federal_state_ids, [id])
      |> load_periods()

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_only_vacation_type", %{"id" => id}, socket) do
    id = String.to_integer(id)

    socket =
      socket
      |> assign(:selected_vacation_type_ids, [id])
      |> load_periods()

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_only_year", %{"year" => year}, socket) do
    year = String.to_integer(year)

    socket =
      socket
      |> assign(:selected_years, [year])
      |> load_periods()

    {:noreply, socket}
  end

  defp apply_filters(socket, params) do
    socket
    |> assign(:selected_federal_state_ids, parse_ids(params["federal_state_ids"]))
    |> assign(:selected_vacation_type_ids, parse_ids(params["vacation_type_ids"]))
    |> assign(:selected_years, parse_years(params["years"]))
  end

  defp update_filters(socket, params) do
    federal_state_ids = get_checkbox_values(params, "federal_state_")
    vacation_type_ids = get_checkbox_values(params, "vacation_type_")
    years = get_checkbox_values(params, "year_")

    socket
    |> assign(:selected_federal_state_ids, federal_state_ids)
    |> assign(:selected_vacation_type_ids, vacation_type_ids)
    |> assign(:selected_years, years)
  end

  defp get_checkbox_values(params, prefix) do
    params
    |> Enum.filter(fn {key, value} -> String.starts_with?(key, prefix) && value == "true" end)
    |> Enum.map(fn {key, _} ->
      value = String.replace(key, prefix, "")
      if String.match?(value, ~r/^\d+$/), do: String.to_integer(value), else: value
    end)
  end

  defp parse_ids(nil), do: []

  defp parse_ids(ids) when is_binary(ids) do
    ids
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.to_integer/1)
  end

  defp parse_ids(ids) when is_list(ids), do: ids

  defp parse_years(nil), do: [Date.utc_today().year]

  defp parse_years(years) when is_binary(years) do
    years
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.to_integer/1)
  end

  defp parse_years(years) when is_list(years), do: years

  defp load_periods(socket) do
    query = build_query(socket.assigns)

    periods =
      query
      |> apply_sorting(socket.assigns.sort_by, socket.assigns.sort_direction)
      |> preload([:location, :holiday_or_vacation_type])
      |> Repo.all()

    # Calculate the additional count for each unchecked item
    federal_state_counts = calculate_federal_state_counts(socket.assigns)
    vacation_type_counts = calculate_vacation_type_counts(socket.assigns)
    year_counts = calculate_year_counts(socket.assigns)

    socket
    |> assign(:periods, periods)
    |> assign(:federal_state_counts, federal_state_counts)
    |> assign(:vacation_type_counts, vacation_type_counts)
    |> assign(:year_counts, year_counts)
  end

  defp apply_sorting(query, [:federal_state | rest], direction) do
    query
    |> order_by([p, l], [{^direction, l.name}])
    |> apply_sorting(rest, direction)
  end

  defp apply_sorting(query, [:vacation_type | rest], direction) do
    # Check if vacation_type is already joined
    if has_named_binding?(query, :vacation_type) do
      query
      |> order_by([p, l, vacation_type: vt], [{^direction, vt.name}])
      |> apply_sorting(rest, direction)
    else
      query
      |> join(:inner, [p, l], vt in assoc(p, :holiday_or_vacation_type), as: :vacation_type)
      |> order_by([p, l, vacation_type: vt], [{^direction, vt.name}])
      |> apply_sorting(rest, direction)
    end
  end

  defp apply_sorting(query, [:starts_on | rest], direction) do
    query
    |> order_by([p], [{^direction, p.starts_on}])
    |> apply_sorting(rest, direction)
  end

  defp apply_sorting(query, [:ends_on | rest], direction) do
    query
    |> order_by([p], [{^direction, p.ends_on}])
    |> apply_sorting(rest, direction)
  end

  defp apply_sorting(query, [], _direction), do: query

  defp build_query(assigns) do
    # Return empty query if any of the selections is empty
    if assigns.selected_federal_state_ids == [] or
         assigns.selected_vacation_type_ids == [] or
         assigns.selected_years == [] do
      # Return a query that will always return empty results
      from(p in Period, where: false)
    else
      Period
      |> where([p], p.is_school_vacation == true)
      |> join(:inner, [p], l in assoc(p, :location))
      |> where([p, l], l.is_federal_state == true)
      |> filter_by_federal_states(assigns.selected_federal_state_ids)
      |> filter_by_vacation_types(assigns.selected_vacation_type_ids)
      |> filter_by_years(assigns.selected_years)
    end
  end

  defp filter_by_federal_states(query, []), do: query

  defp filter_by_federal_states(query, federal_state_ids) do
    where(query, [p, l], p.location_id in ^federal_state_ids)
  end

  defp filter_by_vacation_types(query, []), do: query

  defp filter_by_vacation_types(query, vacation_type_ids) do
    where(query, [p, l], p.holiday_or_vacation_type_id in ^vacation_type_ids)
  end

  defp filter_by_years(query, []), do: query

  defp filter_by_years(query, years) do
    year_conditions =
      Enum.map(years, fn year ->
        start_date = Date.new!(year, 1, 1)
        end_date = Date.new!(year, 12, 31)

        dynamic(
          [p, l],
          (p.starts_on >= ^start_date and p.starts_on <= ^end_date) or
            (p.ends_on >= ^start_date and p.ends_on <= ^end_date) or
            (p.starts_on <= ^start_date and p.ends_on >= ^end_date)
        )
      end)

    combined_condition =
      Enum.reduce(year_conditions, false, fn condition, acc ->
        dynamic([p, l], ^acc or ^condition)
      end)

    where(query, ^combined_condition)
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

    # Ensure current year and next year are included even if no periods exist
    current_year = Date.utc_today().year
    next_year = current_year + 1

    years
    |> Enum.concat([current_year, next_year])
    |> Enum.uniq()
    |> Enum.sort(:desc)
  end

  defp calculate_federal_state_counts(assigns) do
    # Only calculate if there are selections in vacation types and years
    if assigns.selected_vacation_type_ids == [] or assigns.selected_years == [] do
      %{}
    else
      # Only calculate counts for unchecked federal states
      unchecked_ids =
        assigns.federal_states
        |> Enum.map(& &1.id)
        |> Enum.reject(&(&1 in assigns.selected_federal_state_ids))

      # Get current count with existing selections
      current_count =
        if assigns.selected_federal_state_ids == [] do
          0
        else
          Period
          |> where([p], p.is_school_vacation == true)
          |> join(:inner, [p], l in assoc(p, :location))
          |> where([p, l], l.is_federal_state == true)
          |> filter_by_federal_states(assigns.selected_federal_state_ids)
          |> filter_by_vacation_types(assigns.selected_vacation_type_ids)
          |> filter_by_years(assigns.selected_years)
          |> Repo.aggregate(:count)
        end

      unchecked_ids
      |> Enum.map(fn fs_id ->
        # Build query with this federal state added to current selection
        test_selection = [fs_id | assigns.selected_federal_state_ids]

        count =
          Period
          |> where([p], p.is_school_vacation == true)
          |> join(:inner, [p], l in assoc(p, :location))
          |> where([p, l], l.is_federal_state == true)
          |> where([p, l], p.location_id in ^test_selection)
          |> filter_by_vacation_types(assigns.selected_vacation_type_ids)
          |> filter_by_years(assigns.selected_years)
          |> Repo.aggregate(:count)

        additional = count - current_count

        {fs_id, additional}
      end)
      |> Enum.into(%{})
    end
  end

  defp calculate_vacation_type_counts(assigns) do
    # Only calculate if there are selections in federal states and years
    if assigns.selected_federal_state_ids == [] or assigns.selected_years == [] do
      %{}
    else
      # Only calculate counts for unchecked vacation types
      unchecked_ids =
        assigns.vacation_types
        |> Enum.map(& &1.id)
        |> Enum.reject(&(&1 in assigns.selected_vacation_type_ids))

      # Get current count with existing selections
      current_count =
        if assigns.selected_vacation_type_ids == [] do
          0
        else
          Period
          |> where([p], p.is_school_vacation == true)
          |> join(:inner, [p], l in assoc(p, :location))
          |> where([p, l], l.is_federal_state == true)
          |> filter_by_federal_states(assigns.selected_federal_state_ids)
          |> filter_by_vacation_types(assigns.selected_vacation_type_ids)
          |> filter_by_years(assigns.selected_years)
          |> Repo.aggregate(:count)
        end

      unchecked_ids
      |> Enum.map(fn vt_id ->
        # Build query with this vacation type added to current selection
        test_selection = [vt_id | assigns.selected_vacation_type_ids]

        count =
          Period
          |> where([p], p.is_school_vacation == true)
          |> join(:inner, [p], l in assoc(p, :location))
          |> where([p, l], l.is_federal_state == true)
          |> filter_by_federal_states(assigns.selected_federal_state_ids)
          |> where([p, l], p.holiday_or_vacation_type_id in ^test_selection)
          |> filter_by_years(assigns.selected_years)
          |> Repo.aggregate(:count)

        additional = count - current_count

        {vt_id, additional}
      end)
      |> Enum.into(%{})
    end
  end

  defp calculate_year_counts(assigns) do
    # Only calculate if there are selections in federal states and vacation types
    if assigns.selected_federal_state_ids == [] or assigns.selected_vacation_type_ids == [] do
      %{}
    else
      # Only calculate counts for unchecked years
      unchecked_years =
        assigns.available_years
        |> Enum.reject(&(&1 in assigns.selected_years))

      # Get current count with existing selections
      current_count =
        if assigns.selected_years == [] do
          0
        else
          Period
          |> where([p], p.is_school_vacation == true)
          |> join(:inner, [p], l in assoc(p, :location))
          |> where([p, l], l.is_federal_state == true)
          |> filter_by_federal_states(assigns.selected_federal_state_ids)
          |> filter_by_vacation_types(assigns.selected_vacation_type_ids)
          |> filter_by_years(assigns.selected_years)
          |> Repo.aggregate(:count)
        end

      unchecked_years
      |> Enum.map(fn year ->
        # Build query with this year added to current selection
        test_selection = [year | assigns.selected_years]

        count =
          Period
          |> where([p], p.is_school_vacation == true)
          |> join(:inner, [p], l in assoc(p, :location))
          |> where([p, l], l.is_federal_state == true)
          |> filter_by_federal_states(assigns.selected_federal_state_ids)
          |> filter_by_vacation_types(assigns.selected_vacation_type_ids)
          |> filter_by_years(test_selection)
          |> Repo.aggregate(:count)

        additional = count - current_count

        {year, additional}
      end)
      |> Enum.into(%{})
    end
  end

  defp render_sort_indicator(sort_by, sort_direction, field) do
    if sort_by == [field] do
      if sort_direction == :asc do
        Phoenix.HTML.raw("""
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4">
          <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 6.75L12 3m0 0l3.75 3.75M12 3v18" />
        </svg>
        """)
      else
        Phoenix.HTML.raw("""
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 17.25L12 21m0 0l-3.75-3.75M12 21V3" />
        </svg>
        """)
      end
    else
      Phoenix.HTML.raw("""
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4 text-gray-400">
        <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 15L12 18.75 15.75 15m-7.5-6L12 5.25 15.75 9" />
      </svg>
      """)
    end
  end

  defp get_preselected_federal_states(session, all_federal_states) do
    # Extract recent locations from session
    recent_locations = session["recent_locations"] || ""

    if recent_locations == "" do
      # No cookies, select all federal states
      Enum.map(all_federal_states, & &1.id)
    else
      # Parse locations from cookie
      locations =
        LocationTrackingHelpers.get_recent_locations(%{"recent_locations" => recent_locations})

      # Extract federal state IDs from locations
      federal_state_ids =
        locations
        |> Enum.map(&extract_federal_state_id/1)
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()

      if federal_state_ids == [] do
        # No valid federal states found, select all
        Enum.map(all_federal_states, & &1.id)
      else
        federal_state_ids
      end
    end
  end

  defp extract_federal_state_id({"f", slug}) do
    # Direct federal state reference
    # Need to find the federal state - we don't know the country, so we'll query directly
    query =
      from(l in MehrSchulferien.Locations.Location,
        where: l.slug == ^slug and l.is_federal_state == true,
        limit: 1
      )

    case Repo.one(query) do
      %{id: id} -> id
      _ -> nil
    end
  end

  defp extract_federal_state_id({"c", slug}) do
    # City - need to traverse up to federal state
    case MehrSchulferien.Locations.get_city_by_slug(slug) do
      nil -> nil
      city -> get_federal_state_id_from_location(city)
    end
  end

  defp extract_federal_state_id({"s", slug}) do
    # School - need to traverse up to federal state
    case MehrSchulferien.Locations.get_school_by_slug(slug) do
      nil -> nil
      school -> get_federal_state_id_from_location(school)
    end
  end

  defp extract_federal_state_id(_), do: nil

  defp get_federal_state_id_from_location(location) do
    case MehrSchulferien.Periods.get_school_federal_state(location.id) do
      %{id: federal_state_id} -> federal_state_id
      _ -> nil
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
              <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div>
                  <div class="flex justify-between items-center mb-3">
                    <label class="text-sm font-medium text-gray-700 dark:text-gray-300">
                      Bundesländer
                    </label>
                    <div class="flex gap-2">
                      <button
                        type="button"
                        phx-click="select_all_federal_states"
                        class="text-xs text-primary-600 hover:text-primary-800 dark:text-primary-400 dark:hover:text-primary-300"
                      >
                        Alle
                      </button>
                      <span class="text-xs text-gray-400">/</span>
                      <button
                        type="button"
                        phx-click="select_none_federal_states"
                        class="text-xs text-primary-600 hover:text-primary-800 dark:text-primary-400 dark:hover:text-primary-300"
                      >
                        Keine
                      </button>
                    </div>
                  </div>
                  <div class="space-y-2">
                    <div :for={fs <- @federal_states} class="flex items-center group">
                      <input
                        type="checkbox"
                        id={"federal_state_#{fs.id}"}
                        name={"federal_state_#{fs.id}"}
                        value="true"
                        checked={fs.id in @selected_federal_state_ids}
                        class="h-4 w-4 text-primary-600 rounded border-gray-300 focus:ring-primary-500"
                      />
                      <label
                        for={"federal_state_#{fs.id}"}
                        class="ml-2 text-sm text-gray-700 dark:text-gray-300"
                      >
                        {fs.name}
                        <%= if fs.id not in @selected_federal_state_ids do %>
                          <% count = Map.get(@federal_state_counts, fs.id, 0) %>
                          <%= if count > 0 do %>
                            <span class="text-gray-500">(+{count})</span>
                          <% end %>
                        <% end %>
                      </label>
                      <button
                        type="button"
                        phx-click="select_only_federal_state"
                        phx-value-id={fs.id}
                        class="text-xs text-gray-400 hover:text-primary-600 dark:hover:text-primary-400 opacity-0 group-hover:opacity-100 transition-opacity ml-3"
                      >
                        nur
                      </button>
                    </div>
                  </div>
                </div>

                <div>
                  <div class="flex justify-between items-center mb-3">
                    <label class="text-sm font-medium text-gray-700 dark:text-gray-300">
                      Ferienarten
                    </label>
                    <div class="flex gap-2">
                      <button
                        type="button"
                        phx-click="select_all_vacation_types"
                        class="text-xs text-primary-600 hover:text-primary-800 dark:text-primary-400 dark:hover:text-primary-300"
                      >
                        Alle
                      </button>
                      <span class="text-xs text-gray-400">/</span>
                      <button
                        type="button"
                        phx-click="select_none_vacation_types"
                        class="text-xs text-primary-600 hover:text-primary-800 dark:text-primary-400 dark:hover:text-primary-300"
                      >
                        Keine
                      </button>
                    </div>
                  </div>
                  <div class="space-y-2">
                    <div :for={vt <- @vacation_types} class="flex items-center group">
                      <input
                        type="checkbox"
                        id={"vacation_type_#{vt.id}"}
                        name={"vacation_type_#{vt.id}"}
                        value="true"
                        checked={vt.id in @selected_vacation_type_ids}
                        class="h-4 w-4 text-primary-600 rounded border-gray-300 focus:ring-primary-500"
                      />
                      <label
                        for={"vacation_type_#{vt.id}"}
                        class="ml-2 text-sm text-gray-700 dark:text-gray-300"
                      >
                        {vt.name}
                        <%= if vt.id not in @selected_vacation_type_ids do %>
                          <% count = Map.get(@vacation_type_counts, vt.id, 0) %>
                          <%= if count > 0 do %>
                            <span class="text-gray-500">(+{count})</span>
                          <% end %>
                        <% end %>
                      </label>
                      <button
                        type="button"
                        phx-click="select_only_vacation_type"
                        phx-value-id={vt.id}
                        class="text-xs text-gray-400 hover:text-primary-600 dark:hover:text-primary-400 opacity-0 group-hover:opacity-100 transition-opacity ml-3"
                      >
                        nur
                      </button>
                    </div>
                  </div>
                </div>

                <div>
                  <div class="flex justify-between items-center mb-3">
                    <label class="text-sm font-medium text-gray-700 dark:text-gray-300">
                      Jahre
                    </label>
                    <div class="flex gap-2">
                      <button
                        type="button"
                        phx-click="select_all_years"
                        class="text-xs text-primary-600 hover:text-primary-800 dark:text-primary-400 dark:hover:text-primary-300"
                      >
                        Alle
                      </button>
                      <span class="text-xs text-gray-400">/</span>
                      <button
                        type="button"
                        phx-click="select_none_years"
                        class="text-xs text-primary-600 hover:text-primary-800 dark:text-primary-400 dark:hover:text-primary-300"
                      >
                        Keine
                      </button>
                    </div>
                  </div>
                  <div class="space-y-2">
                    <div :for={year <- @available_years} class="flex items-center group">
                      <input
                        type="checkbox"
                        id={"year_#{year}"}
                        name={"year_#{year}"}
                        value="true"
                        checked={year in @selected_years}
                        class="h-4 w-4 text-primary-600 rounded border-gray-300 focus:ring-primary-500"
                      />
                      <label
                        for={"year_#{year}"}
                        class="ml-2 text-sm text-gray-700 dark:text-gray-300"
                      >
                        {year}
                        <%= if year not in @selected_years do %>
                          <% count = Map.get(@year_counts, year, 0) %>
                          <%= if count > 0 do %>
                            <span class="text-gray-500">(+{count})</span>
                          <% end %>
                        <% end %>
                      </label>
                      <button
                        type="button"
                        phx-click="select_only_year"
                        phx-value-year={year}
                        class="text-xs text-gray-400 hover:text-primary-600 dark:hover:text-primary-400 opacity-0 group-hover:opacity-100 transition-opacity ml-3"
                      >
                        nur
                      </button>
                    </div>
                  </div>
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
                  <span class="text-gray-900 dark:text-gray-100 ml-1">
                    {format_date(period.starts_on)}
                  </span>
                </div>
                <div>
                  <span class="text-gray-500 dark:text-gray-400">Bis:</span>
                  <span class="text-gray-900 dark:text-gray-100 ml-1">
                    {format_date(period.ends_on)}
                  </span>
                </div>
                <div>
                  <span class="text-gray-500 dark:text-gray-400">Dauer:</span>
                  <span class="text-gray-900 dark:text-gray-100 ml-1">
                    {period_duration(period)} Tage
                  </span>
                </div>
              </div>
            </div>

            <div
              :if={@periods == []}
              class="bg-white dark:bg-gray-800 rounded-lg shadow p-8 text-center"
            >
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
                    <.th>
                      <button
                        type="button"
                        phx-click="sort_by"
                        phx-value-field="federal_state"
                        class="flex items-center gap-1 hover:text-primary-600"
                      >
                        Bundesland {render_sort_indicator(@sort_by, @sort_direction, :federal_state)}
                      </button>
                    </.th>
                    <.th>
                      <button
                        type="button"
                        phx-click="sort_by"
                        phx-value-field="vacation_type"
                        class="flex items-center gap-1 hover:text-primary-600"
                      >
                        Ferienart {render_sort_indicator(@sort_by, @sort_direction, :vacation_type)}
                      </button>
                    </.th>
                    <.th>
                      <button
                        type="button"
                        phx-click="sort_by"
                        phx-value-field="starts_on"
                        class="flex items-center gap-1 hover:text-primary-600"
                      >
                        Beginn {render_sort_indicator(@sort_by, @sort_direction, :starts_on)}
                      </button>
                    </.th>
                    <.th>
                      <button
                        type="button"
                        phx-click="sort_by"
                        phx-value-field="ends_on"
                        class="flex items-center gap-1 hover:text-primary-600"
                      >
                        Ende {render_sort_indicator(@sort_by, @sort_direction, :ends_on)}
                      </button>
                    </.th>
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
