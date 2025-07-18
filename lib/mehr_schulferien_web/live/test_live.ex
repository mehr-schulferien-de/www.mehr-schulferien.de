defmodule MehrSchulferienWeb.TestLive do
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferienWeb.NavigationHelper
  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods}

  @impl true
  def mount(_params, _session, socket) do
    # Get navigation years for the navigation component
    today = DateHelpers.today_berlin()
    {current_year, next_year} = NavigationHelper.get_navigation_years(today)

    # Get federal states for dropdown
    federal_states = get_federal_states()

    # Get total school count for the initial display
    total_schools = get_total_school_count()

    socket =
      socket
      |> assign(:current_year, current_year)
      |> assign(:next_year, next_year)
      |> assign(:today, today)
      |> assign(:page_title, "Schulferien und Feiertage")
      |> assign(:federal_states, federal_states)
      |> assign(:search_params, %{
        "location" => "",
        "school_name" => "",
        "federal_state_id" => ""
      })
      |> assign(:schools, [])
      |> assign(:searching, false)
      |> assign(:sort_by, nil)
      |> assign(:sort_order, :asc)
      |> assign(:federal_state_overview, nil)
      |> assign(:cities_with_schools, [])
      |> assign(:show_all_schools, false)
      |> assign(:expanded_cities, MapSet.new())
      |> assign(:total_school_count, 0)
      |> assign(:total_city_count, 0)
      |> assign(:total_schools_in_system, total_schools)

    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"search" => search_params}, socket) do
    schools = search_schools_with_federal_state(search_params)
    sorted_schools = sort_schools(schools, socket.assigns.sort_by, socket.assigns.sort_order)

    {:noreply,
     assign(socket,
       schools: sorted_schools,
       searching: false,
       search_params: search_params
     )}
  end

  @impl true
  def handle_event("validate", %{"search" => search_params}, socket) do
    location = Map.get(search_params, "location", "")
    school_name = Map.get(search_params, "school_name", "")
    federal_state_id = Map.get(search_params, "federal_state_id", "")

    # Always update search params first
    socket = assign(socket, :search_params, search_params)

    # Progressive search: federal state -> location -> school name
    socket =
      cond do
        # If nothing is filled, clear results
        federal_state_id == "" and location == "" and school_name == "" ->
          clear_search_results(socket)

        # If location is a zip code, always handle it with auto federal state detection
        String.length(location) >= 2 and is_zip_code?(location) ->
          handle_zip_code_search_with_auto_federal_state(socket, location, school_name)

        # Federal state is selected
        federal_state_id != "" ->
          socket = handle_federal_state_search(socket, federal_state_id)

          # Further filter by location if provided
          socket =
            if String.length(location) >= 2 do
              filter_by_city_name(socket, location)
            else
              socket
            end

          # Further filter by school name if provided  
          if String.length(school_name) >= 2 do
            filter_by_school_name(socket, school_name)
          else
            socket
          end

        # Only location is provided (no federal state selected) - must be city name
        String.length(location) >= 2 ->
          handle_city_search_all_states(socket, location, school_name)

        # Only school name is provided
        String.length(school_name) >= 2 ->
          handle_school_search_all_states(socket, school_name)

        # Default: clear results
        true ->
          clear_search_results(socket)
      end

    {:noreply, update_counts(socket)}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    socket =
      socket
      |> assign(:search_params, %{
        "location" => "",
        "school_name" => "",
        "federal_state_id" => ""
      })
      |> clear_search_results()

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_city", %{"city-id" => city_id}, socket) do
    city_id = String.to_integer(city_id)
    expanded_cities = socket.assigns.expanded_cities

    expanded_cities =
      if MapSet.member?(expanded_cities, city_id) do
        MapSet.delete(expanded_cities, city_id)
      else
        MapSet.put(expanded_cities, city_id)
      end

    socket = assign(socket, :expanded_cities, expanded_cities)

    # Push an event to maintain scroll position
    {:noreply, push_event(socket, "maintain-scroll", %{element_id: "city-card-#{city_id}"})}
  end

  @impl true
  def handle_event("sort", %{"field" => field}, socket) do
    field_atom = String.to_atom(field)

    {sort_by, sort_order} =
      if socket.assigns.sort_by == field_atom do
        # Toggle order if clicking the same field
        {field_atom, if(socket.assigns.sort_order == :asc, do: :desc, else: :asc)}
      else
        # New field, default to ascending
        {field_atom, :asc}
      end

    sorted_schools = sort_schools(socket.assigns.schools, sort_by, sort_order)

    {:noreply,
     assign(socket,
       schools: sorted_schools,
       sort_by: sort_by,
       sort_order: sort_order
     )}
  end

  defp get_federal_states do
    country = Locations.get_country_by_slug!("d")

    Locations.list_federal_states(country)
    |> Enum.map(fn state -> {state.name, state.id} end)
    |> Enum.sort_by(&elem(&1, 0))
  end

  defp get_total_school_count do
    import Ecto.Query
    alias MehrSchulferien.Repo

    from(l in MehrSchulferien.Locations.Location,
      where: l.is_school == true,
      select: count(l.id)
    )
    |> Repo.one()
  end

  defp search_schools_with_federal_state(params) do
    # If federal state is selected, filter by it
    federal_state_id = Map.get(params, "federal_state_id", "")

    schools = Locations.search_schools(params)

    if federal_state_id != "" do
      Enum.filter(schools, fn school ->
        # Check if school's parent location (city) belongs to the selected federal state
        school.parent_location &&
          school.parent_location.parent_location_id == String.to_integer(federal_state_id)
      end)
    else
      schools
    end
  end

  defp sort_schools(schools, nil, _order), do: schools

  defp sort_schools(schools, field, order) do
    Enum.sort_by(
      schools,
      fn school ->
        case field do
          :name ->
            school.name || ""

          :street ->
            if school.address, do: school.address.street || "", else: ""

          :zip_code ->
            if school.address, do: school.address.zip_code || "", else: ""

          :city ->
            if school.parent_location, do: school.parent_location.name || "", else: ""

          _ ->
            ""
        end
      end,
      if(order == :asc, do: &<=/2, else: &>=/2)
    )
  end

  defp load_federal_state_overview(federal_state_id, today) do
    federal_state = Locations.get_location!(String.to_integer(federal_state_id))
    country = Locations.get_location!(federal_state.parent_location_id)

    # Get city and school counts
    counties_with_cities = Locations.list_counties_with_cities_having_schools(federal_state)

    # Count total cities and schools
    {city_count, school_count} =
      Enum.reduce(counties_with_cities, {0, 0}, fn {_county, cities}, {c_acc, s_acc} ->
        city_count = length(cities)
        school_count = Enum.reduce(cities, 0, fn %{school_count: count}, acc -> acc + count end)
        {c_acc + city_count, s_acc + school_count}
      end)

    # Get upcoming vacations and holidays
    location_ids = [country.id, federal_state.id]
    # Look ahead 1 year
    future_date = Date.add(today, 365)

    # Get school vacation periods
    vacation_periods =
      Periods.list_school_vacation_periods(location_ids, today, future_date)
      # Take next 5 vacation periods
      |> Enum.take(5)

    # Get public holiday periods
    public_periods =
      Periods.list_public_periods(location_ids, today, future_date)
      # Take next 5 public holidays
      |> Enum.take(5)

    # Calculate bridge days for current year
    current_year = today.year
    {:ok, year_start} = Date.new(current_year, 1, 1)
    {:ok, year_end} = Date.new(current_year, 12, 31)

    # Get all public periods for the year
    year_public_periods =
      Periods.list_public_everybody_periods(location_ids, year_start, year_end)

    bridge_day_map = Periods.group_by_interval(year_public_periods)

    # Get next 3 bridge day opportunities
    next_bridge_days = get_next_bridge_days(bridge_day_map, year_public_periods, today)

    %{
      federal_state: federal_state,
      country: country,
      city_count: city_count,
      school_count: school_count,
      next_vacations: vacation_periods,
      next_holidays: public_periods,
      next_bridge_days: next_bridge_days
    }
  end

  defp load_all_cities_with_schools(federal_state_id) do
    import Ecto.Query
    alias MehrSchulferien.Repo

    federal_state_id_int = String.to_integer(federal_state_id)

    # Query to get all schools in the federal state with their cities
    query =
      from s in MehrSchulferien.Locations.Location,
        join: city in assoc(s, :parent_location),
        join: county in assoc(city, :parent_location),
        where: s.is_school == true,
        where: county.parent_location_id == ^federal_state_id_int,
        preload: [:address, parent_location: :parent_location],
        order_by: [city.name, s.name]

    schools = Repo.all(query)

    # Group schools by city
    cities_with_schools =
      schools
      |> Enum.group_by(& &1.parent_location)
      |> Enum.map(fn {city, schools} ->
        {city, schools}
      end)
      |> Enum.sort_by(fn {city, _schools} -> city.name end)

    cities_with_schools
  end

  defp format_zip_codes_list([]), do: ""
  defp format_zip_codes_list([single]), do: single

  defp format_zip_codes_list(zip_codes) do
    {last, rest} = List.pop_at(zip_codes, -1)
    Enum.join(rest, ", ") <> " und " <> last
  end

  defp handle_federal_state_search(socket, federal_state_id) do
    try do
      federal_state_overview = load_federal_state_overview(federal_state_id, socket.assigns.today)
      cities_with_schools = load_all_cities_with_schools(federal_state_id)

      socket
      |> assign(:federal_state_overview, federal_state_overview)
      |> assign(:cities_with_schools, cities_with_schools)
      |> assign(:show_all_schools, true)
      |> assign(:schools, [])
    rescue
      e ->
        IO.inspect(e, label: "Error loading federal state data")
        socket
    end
  end

  # Helper functions for the new search logic
  defp is_zip_code?(nil), do: false

  defp is_zip_code?(text) do
    String.length(text) == 5 and Regex.match?(~r/^\d{5}$/, text)
  end

  defp clear_search_results(socket) do
    socket
    |> assign(:federal_state_overview, nil)
    |> assign(:cities_with_schools, [])
    |> assign(:show_all_schools, false)
    |> assign(:schools, [])
    |> assign(:expanded_cities, MapSet.new())
    |> assign(:total_school_count, 0)
    |> assign(:total_city_count, 0)
  end

  defp update_counts(socket) do
    total_schools =
      Enum.reduce(socket.assigns.cities_with_schools, 0, fn {_city, schools}, acc ->
        acc + length(schools)
      end)

    socket
    |> assign(:total_school_count, total_schools)
    |> assign(:total_city_count, length(socket.assigns.cities_with_schools))
  end

  defp filter_by_city_name(socket, city_name) do
    city_pattern = String.downcase(city_name)

    # Filter existing cities by name
    filtered_cities =
      socket.assigns.cities_with_schools
      |> Enum.filter(fn {city, _schools} ->
        String.contains?(String.downcase(city.name), city_pattern)
      end)

    assign(socket, :cities_with_schools, filtered_cities)
  end

  defp filter_by_school_name(socket, school_name) do
    school_pattern = String.downcase(school_name)

    # Filter schools within existing cities
    filtered_cities =
      socket.assigns.cities_with_schools
      |> Enum.map(fn {city, schools} ->
        filtered_schools =
          Enum.filter(schools, fn school ->
            String.contains?(String.downcase(school.name), school_pattern)
          end)

        {city, filtered_schools}
      end)
      |> Enum.filter(fn {_city, schools} -> length(schools) > 0 end)

    assign(socket, :cities_with_schools, filtered_cities)
  end

  defp handle_zip_code_search_with_auto_federal_state(socket, zip_code, school_name) do
    import Ecto.Query
    alias MehrSchulferien.Repo

    # Find schools with this zip code
    query =
      from s in MehrSchulferien.Locations.Location,
        join: a in MehrSchulferien.Maps.Address,
        on: a.school_location_id == s.id,
        join: city in assoc(s, :parent_location),
        join: county in assoc(city, :parent_location),
        join: federal_state in assoc(county, :parent_location),
        where: s.is_school == true and a.zip_code == ^zip_code,
        preload: [:address, parent_location: [parent_location: :parent_location]],
        order_by: s.name

    schools = Repo.all(query)

    if length(schools) > 0 do
      # Group schools by city
      cities_with_schools =
        schools
        |> Enum.group_by(& &1.parent_location)
        |> Enum.map(fn {city, schools} -> {city, schools} end)

      # Check if all schools are in the same federal state
      federal_states =
        cities_with_schools
        |> Enum.map(fn {city, _} -> city.parent_location.parent_location end)
        |> Enum.uniq_by(& &1.id)

      # Update search params based on federal states found
      search_params =
        if length(federal_states) == 1 do
          # All schools in same federal state - use it
          federal_state = hd(federal_states)
          Map.put(socket.assigns.search_params, "federal_state_id", to_string(federal_state.id))
        else
          # Multiple federal states or other issue - reset to default
          Map.put(socket.assigns.search_params, "federal_state_id", "")
        end

      socket = assign(socket, :search_params, search_params)

      # Load federal state overview if single state
      socket =
        if length(federal_states) == 1 do
          federal_state = hd(federal_states)

          federal_state_overview =
            load_federal_state_overview(to_string(federal_state.id), socket.assigns.today)

          socket
          |> assign(:federal_state_overview, federal_state_overview)
        else
          socket
        end

      socket =
        socket
        |> assign(:cities_with_schools, cities_with_schools)
        |> assign(:show_all_schools, true)

      # Further filter by school name if provided
      if String.length(school_name) >= 2 do
        filter_by_school_name(socket, school_name)
      else
        socket
      end
    else
      # No schools found - reset federal state to default
      search_params = Map.put(socket.assigns.search_params, "federal_state_id", "")

      socket
      |> assign(:search_params, search_params)
      |> clear_search_results()
    end
  end

  defp handle_city_search_all_states(socket, city_name, school_name) do
    import Ecto.Query
    alias MehrSchulferien.Repo

    city_pattern = "%#{city_name}%"

    # Search for cities across all federal states
    query =
      from c in MehrSchulferien.Locations.Location,
        join: county in assoc(c, :parent_location),
        join: federal_state in assoc(county, :parent_location),
        where: c.is_city == true and ilike(c.name, ^city_pattern),
        preload: [parent_location: :parent_location]

    cities = Repo.all(query)

    if length(cities) > 0 do
      # Load schools for each city
      cities_with_schools =
        Enum.map(cities, fn city ->
          schools_query =
            from s in MehrSchulferien.Locations.Location,
              where: s.is_school == true and s.parent_location_id == ^city.id,
              preload: [:address],
              order_by: s.name

          schools = Repo.all(schools_query)
          {city, schools}
        end)
        |> Enum.filter(fn {_city, schools} -> length(schools) > 0 end)

      if length(cities_with_schools) > 0 do
        # If all cities are in the same federal state, set it
        federal_states =
          cities_with_schools
          |> Enum.map(fn {city, _} -> city.parent_location.parent_location end)
          |> Enum.uniq_by(& &1.id)

        socket =
          if length(federal_states) == 1 do
            federal_state = hd(federal_states)

            federal_state_overview =
              load_federal_state_overview(to_string(federal_state.id), socket.assigns.today)

            search_params =
              Map.put(
                socket.assigns.search_params,
                "federal_state_id",
                to_string(federal_state.id)
              )

            socket
            |> assign(:federal_state_overview, federal_state_overview)
            |> assign(:search_params, search_params)
          else
            socket
          end

        socket =
          socket
          |> assign(:cities_with_schools, cities_with_schools)
          |> assign(:show_all_schools, true)

        # Further filter by school name if provided
        if String.length(school_name) >= 2 do
          filter_by_school_name(socket, school_name)
        else
          socket
        end
      else
        clear_search_results(socket)
      end
    else
      clear_search_results(socket)
    end
  end

  defp handle_school_search_all_states(socket, school_name) do
    import Ecto.Query
    alias MehrSchulferien.Repo

    school_pattern = "%#{school_name}%"

    # Search for schools across all federal states
    query =
      from s in MehrSchulferien.Locations.Location,
        join: city in assoc(s, :parent_location),
        join: county in assoc(city, :parent_location),
        join: federal_state in assoc(county, :parent_location),
        where: s.is_school == true and ilike(s.name, ^school_pattern),
        preload: [:address, parent_location: [parent_location: :parent_location]],
        order_by: s.name,
        # Limit results for performance
        limit: 500

    schools = Repo.all(query)

    if length(schools) > 0 do
      # Group schools by city
      cities_with_schools =
        schools
        |> Enum.group_by(& &1.parent_location)
        |> Enum.map(fn {city, schools} -> {city, schools} end)

      # Check if all schools are in the same federal state
      federal_states =
        cities_with_schools
        |> Enum.map(fn {city, _} -> city.parent_location.parent_location end)
        |> Enum.uniq_by(& &1.id)

      socket =
        if length(federal_states) == 1 do
          # All schools are in the same federal state, load the overview
          federal_state = hd(federal_states)

          federal_state_overview =
            load_federal_state_overview(to_string(federal_state.id), socket.assigns.today)

          socket
          |> assign(:federal_state_overview, federal_state_overview)
        else
          socket
        end

      socket
      |> assign(:cities_with_schools, cities_with_schools)
      |> assign(:show_all_schools, true)
    else
      clear_search_results(socket)
    end
  end

  # Number formatting helper
  defp format_number(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1.")
    |> String.reverse()
  end

  defp format_number(number) when is_float(number) do
    number
    |> Float.round(1)
    |> Float.to_string()
    |> String.replace(".", ",")
  end

  defp get_federal_state_name(nil), do: ""
  defp get_federal_state_name(%{federal_state: %{name: name}}), do: name
  defp get_federal_state_name(_), do: ""

  defp get_next_bridge_days(bridge_day_map, public_periods, today) do
    # Collect all bridge day opportunities
    all_bridge_days =
      for {_num_days, bridge_days} <- bridge_day_map,
          bridge_day <- bridge_days do
        bridge_day
      end

    # Filter for future bridge days and those that meet minimum gain
    all_bridge_days
    |> Enum.filter(fn bridge_day ->
      # Check if bridge day is in the future
      Date.compare(bridge_day.starts_on, today) == :gt
    end)
    |> Enum.filter(fn bridge_day ->
      # Check if it meets minimum gain requirements
      all_periods = Periods.list_periods_with_bridge_day(public_periods, bridge_day)
      MehrSchulferien.BridgeDayCalculations.meets_minimum_gain?(bridge_day, all_periods)
    end)
    |> Enum.sort_by(& &1.starts_on)
    |> Enum.take(3)
    |> Enum.map(fn bridge_day ->
      # Add the connected periods info
      all_periods = Periods.list_periods_with_bridge_day(public_periods, bridge_day)
      total_days = MehrSchulferien.BridgeDayCalculations.get_number_max_days(all_periods)

      %{
        bridge_day: bridge_day,
        vacation_days: bridge_day.number_days,
        total_free_days: total_days,
        gain_factor: Float.round(total_days / bridge_day.number_days, 1)
      }
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mt-4 sm:mt-8 px-4 sm:px-0" id="test-page-container" phx-hook="MaintainScroll">
      <.heading level={1} class="mb-6 sm:mb-8">
        Schulferien und Feiertage
      </.heading>

      <form
        phx-submit="search"
        phx-change="validate"
        class="mb-6 sm:mb-8 bg-white shadow-sm rounded-lg p-4 sm:p-6"
      >
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 sm:gap-6">
          <div>
            <label for="search_federal_state" class="block text-sm font-medium text-gray-700 mb-2">
              Bundesland
            </label>
            <select
              name="search[federal_state_id]"
              id="search_federal_state"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 h-[42px]"
              phx-change="validate"
              value={@search_params["federal_state_id"] || ""}
            >
              <option value="">Alle Bundesländer</option>
              <%= for {name, id} <- @federal_states do %>
                <option
                  value={to_string(id)}
                  selected={@search_params["federal_state_id"] == to_string(id)}
                >
                  <%= name %>
                </option>
              <% end %>
            </select>
          </div>
          <div>
            <label for="search_location" class="block text-sm font-medium text-gray-700 mb-2">
              Stadt oder PLZ
            </label>
            <input
              type="text"
              name="search[location]"
              value={@search_params["location"] || ""}
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              placeholder="z.B. Berlin oder 10115"
              id="search_location"
              phx-debounce="300"
            />
          </div>
          <div>
            <label for="search_school_name" class="block text-sm font-medium text-gray-700 mb-2">
              Schulname
            </label>
            <input
              type="text"
              name="search[school_name]"
              value={@search_params["school_name"] || ""}
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              placeholder="z.B. Gymnasium"
              id="search_school_name"
              phx-debounce="300"
            />
          </div>
        </div>
        <div class="mt-6 flex gap-3">
          <.button type="submit" variant="primary" disabled={@searching}>
            <%= if @searching, do: "Suche läuft...", else: "Suchen" %>
          </.button>
          <button
            type="button"
            phx-click="reset"
            class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Zurücksetzen
          </button>
        </div>
      </form>
      <!-- Prominent Result Counter -->
      <%= if @total_school_count > 0 do %>
        <div class="mb-4 sm:mb-6 bg-green-50 border border-green-200 rounded-lg p-3 sm:p-4 text-center md:text-left">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between">
            <div>
              <span class="font-bold text-lg sm:text-xl text-green-800">
                <%= if @total_school_count == 1 and length(@cities_with_schools) == 1 do %>
                  <% {city, [school | _]} = hd(@cities_with_schools) %> 1 Schule gefunden:
                  <a
                    href={"/ferien/d/schule/#{school.slug}"}
                    class="text-green-800 hover:text-green-900 underline"
                  >
                    <%= school.name %>
                  </a>
                  in <%= city.name %>
                <% else %>
                  <%= format_number(@total_school_count) %> <%= if @total_school_count == 1,
                    do: "Schule",
                    else: "Schulen" %> gefunden
                  <%= if @total_city_count > 0 do %>
                    <span class="text-green-700 ml-2 text-base">
                      <%= if @total_city_count == 1 do %>
                        <% {city, _schools} = hd(@cities_with_schools) %> in <%= city.name %>
                      <% else %>
                        in <%= format_number(@total_city_count) %> <%= if @total_city_count == 1,
                          do: "Stadt",
                          else: "Städten" %>
                      <% end %>
                    </span>
                  <% end %>
                <% end %>
              </span>
            </div>
            <%= if @searching do %>
              <div class="mt-2 sm:mt-0">
                <span class="text-sm text-green-600 animate-pulse">Suche läuft...</span>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>

      <%= if @federal_state_overview do %>
        <div class="mb-6 sm:mb-8 bg-blue-50 border border-blue-200 rounded-lg p-4 sm:p-6">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-4">
            <.heading level={2} class="mb-2 sm:mb-0 text-lg sm:text-xl">
              <%= if length(@cities_with_schools) == 1 do %>
                <% {city, _schools} = hd(@cities_with_schools) %>
                <%= city.name %>, <%= @federal_state_overview.federal_state.name %>
              <% else %>
                <%= @federal_state_overview.federal_state.name %>
              <% end %>
            </.heading>
            <div class="flex gap-4 text-sm text-gray-600">
              <span>
                <span class="font-semibold">
                  <%= format_number(@federal_state_overview.city_count) %>
                </span>
                <%= if @federal_state_overview.city_count ==
                         1,
                       do: "Stadt",
                       else: "Städte" %>
              </span>
              <span>
                <span class="font-semibold">
                  <%= format_number(@federal_state_overview.school_count) %>
                </span>
                <%= if @federal_state_overview.school_count ==
                         1,
                       do: "Schule",
                       else: "Schulen" %>
              </span>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-3 sm:gap-4">
            <a
              href={"/ferien/d/bundesland/#{@federal_state_overview.federal_state.slug}/#{@today.year}"}
              class="bg-white rounded-lg p-3 sm:p-4 shadow-sm hover:shadow-md transition-shadow"
            >
              <.text variant="base" class="font-semibold mb-2">Nächste Schulferien</.text>
              <div class="space-y-1">
                <%= for vacation <- Enum.take(@federal_state_overview.next_vacations, 3) do %>
                  <div class="text-sm">
                    <div class="font-medium">
                      <%= vacation.holiday_or_vacation_type.colloquial %>
                    </div>
                    <div class="text-gray-600">
                      <%= Calendar.strftime(vacation.starts_on, "%d.%m.%Y") %> - <%= Calendar.strftime(
                        vacation.ends_on,
                        "%d.%m.%Y"
                      ) %>
                    </div>
                  </div>
                <% end %>
              </div>
              <div class="mt-3 text-xs text-blue-600 hover:text-blue-800">
                Mehr anzeigen →
              </div>
            </a>

            <a
              href={"/ferien/d/bundesland/#{@federal_state_overview.federal_state.slug}/#{@today.year}"}
              class="bg-white rounded-lg p-3 sm:p-4 shadow-sm hover:shadow-md transition-shadow"
            >
              <.text variant="base" class="font-semibold mb-2">Nächste Feiertage</.text>
              <div class="space-y-1">
                <%= for holiday <- Enum.take(@federal_state_overview.next_holidays, 3) do %>
                  <div class="text-sm">
                    <div class="font-medium">
                      <%= holiday.holiday_or_vacation_type.colloquial %>
                    </div>
                    <div class="text-gray-600">
                      <%= Calendar.strftime(holiday.starts_on, "%d.%m.%Y") %>
                    </div>
                  </div>
                <% end %>
              </div>
              <div class="mt-3 text-xs text-blue-600 hover:text-blue-800">
                Mehr anzeigen →
              </div>
            </a>

            <a
              href={"/brueckentage/d/bundesland/#{@federal_state_overview.federal_state.slug}/#{@today.year}"}
              class="bg-white rounded-lg p-3 sm:p-4 shadow-sm hover:shadow-md transition-shadow"
            >
              <.text variant="base" class="font-semibold mb-2">Nächste Brückentage</.text>
              <div class="space-y-1">
                <%= if length(@federal_state_overview.next_bridge_days) > 0 do %>
                  <%= for bridge_info <- Enum.take(@federal_state_overview.next_bridge_days, 3) do %>
                    <div class="text-sm">
                      <div class="font-medium">
                        <%= bridge_info.vacation_days %> <%= if bridge_info.vacation_days == 1,
                          do: "Tag",
                          else: "Tage" %> Urlaub
                      </div>
                      <div class="text-gray-600">
                        → <%= bridge_info.total_free_days %> Tage frei (×<%= bridge_info.gain_factor %>)
                      </div>
                    </div>
                  <% end %>
                <% else %>
                  <div class="text-sm text-gray-500">
                    Keine Brückentage in nächster Zeit
                  </div>
                <% end %>
              </div>
              <div class="mt-3 text-xs text-blue-600 hover:text-blue-800">
                Mehr anzeigen →
              </div>
            </a>
          </div>
        </div>
      <% end %>

      <%= if @show_all_schools do %>
        <div class="mb-8">
          <.heading level={2} class="mb-3 sm:mb-4 text-lg sm:text-2xl">
            <%= cond do %>
              <% String.length(@search_params["location"] || "") >= 2 and String.length(@search_params["school_name"] || "") >= 2 -> %>
                Suchergebnisse für "<%= @search_params["school_name"] %>" in
                <%= if is_zip_code?(@search_params["location"]) do %>
                  PLZ <%= @search_params["location"] %>
                <% else %>
                  "<%= @search_params["location"] %>"
                <% end %>
                <%= if @federal_state_overview do %>
                  (<%= get_federal_state_name(@federal_state_overview) %>)
                <% end %>
              <% String.length(@search_params["location"] || "") >= 2 -> %>
                Suchergebnisse für
                <%= if is_zip_code?(@search_params["location"]) do %>
                  PLZ <%= @search_params["location"] %>
                <% else %>
                  "<%= @search_params["location"] %>"
                <% end %>
                <%= if @federal_state_overview do %>
                  (<%= get_federal_state_name(@federal_state_overview) %>)
                <% end %>
              <% String.length(@search_params["school_name"] || "") >= 2 -> %>
                Suchergebnisse für "<%= @search_params["school_name"] %>"
                <%= if @federal_state_overview do %>
                  in <%= get_federal_state_name(@federal_state_overview) %>
                <% end %>
              <% @federal_state_overview -> %>
                Alle Städte und Schulen in <%= get_federal_state_name(@federal_state_overview) %>
              <% true -> %>
                Suchergebnisse
            <% end %>
          </.heading>

          <%= if length(@cities_with_schools) > 0 do %>
            <!-- Summary Statistics -->
            <div class="mb-4 sm:mb-6 bg-gray-50 rounded-lg p-3 sm:p-4">
              <div class="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4 text-center">
                <div>
                  <.text variant="small" class="text-xs sm:text-sm text-gray-600">Städte</.text>
                  <.text variant="lead" class="font-bold text-lg sm:text-2xl">
                    <%= format_number(length(@cities_with_schools)) %>
                  </.text>
                </div>
                <div>
                  <.text variant="small" class="text-xs sm:text-sm text-gray-600">
                    Schulen gesamt
                  </.text>
                  <.text variant="lead" class="font-bold text-lg sm:text-2xl">
                    <%= format_number(
                      Enum.reduce(@cities_with_schools, 0, fn {_city, schools}, acc ->
                        acc + length(schools)
                      end)
                    ) %>
                  </.text>
                </div>
                <div>
                  <.text variant="small" class="text-xs sm:text-sm text-gray-600">
                    Ø Schulen pro Stadt
                  </.text>
                  <.text variant="lead" class="font-bold text-lg sm:text-2xl">
                    <%= format_number(
                      Float.round(
                        Enum.reduce(@cities_with_schools, 0, fn {_city, schools}, acc ->
                          acc + length(schools)
                        end) / length(@cities_with_schools),
                        1
                      )
                    ) %>
                  </.text>
                </div>
                <div>
                  <.text variant="small" class="text-xs sm:text-sm text-gray-600">Größte Stadt</.text>
                  <%= case Enum.max_by(@cities_with_schools, fn {_city, schools} -> length(schools) end, fn -> nil end) do %>
                    <% {city, schools} -> %>
                      <a
                        href={"#city-card-#{city.id}"}
                        class="text-sm sm:text-base font-semibold text-blue-600 hover:text-blue-800 hover:underline"
                      >
                        <%= city.name %> (<%= format_number(length(schools)) %>)
                      </a>
                    <% _ -> %>
                      <.text variant="base" class="text-sm sm:text-base font-semibold">-</.text>
                  <% end %>
                </div>
              </div>
            </div>
            <!-- Cities Grid -->
            <div class="grid grid-cols-1 lg:grid-cols-3 gap-3 sm:gap-4 lg:gap-6">
              <%= for {city, schools} <- @cities_with_schools do %>
                <div
                  class="bg-white rounded-lg shadow-sm border border-gray-200 hover:shadow-lg transition-all duration-200"
                  id={"city-card-#{city.id}"}
                >
                  <!-- City Header -->
                  <div class="px-3 sm:px-5 py-2.5 sm:py-4 border-b border-gray-200">
                    <div class="flex items-baseline justify-between gap-2">
                      <h3 class="text-sm sm:text-lg font-semibold text-gray-900 truncate">
                        <%= city.name %>
                      </h3>
                      <span class="text-xs sm:text-sm font-medium text-gray-600 flex-shrink-0 whitespace-nowrap">
                        <%= format_number(length(schools)) %> <%= if length(schools) == 1,
                          do: "Schule",
                          else: "Schulen" %>
                      </span>
                    </div>
                    <% zip_codes =
                      schools
                      |> Enum.map(&(&1.address && &1.address.zip_code))
                      |> Enum.filter(& &1)
                      |> Enum.uniq()
                      |> Enum.sort() %>
                    <%= if length(zip_codes) > 0 do %>
                      <p class="text-sm text-gray-500 mt-1">
                        PLZ-Bereich: <%= format_zip_codes_list(zip_codes) %>
                      </p>
                    <% end %>
                  </div>
                  <!-- Schools List -->
                  <div class="px-3 sm:px-5 py-2 sm:py-4">
                    <ul class="space-y-1.5 sm:space-y-3">
                      <% is_expanded = MapSet.member?(@expanded_cities, city.id) %>
                      <% visible_schools =
                        if length(schools) > 10 && !is_expanded,
                          do: Enum.take(schools, 10),
                          else: schools %>
                      <!-- Schools list -->
                      <%= for {school, index} <- Enum.with_index(visible_schools) do %>
                        <li class={
                          if index < length(visible_schools) - 1,
                            do: "pb-1.5 sm:pb-3 border-b border-gray-100",
                            else: ""
                        }>
                          <a
                            href={"/ferien/d/schule/#{school.slug}"}
                            class="group block hover:translate-x-1 transition-transform duration-150 py-0.5"
                          >
                            <div class="flex items-start justify-between gap-1">
                              <div class="flex-1 min-w-0 pr-1">
                                <p class="text-xs sm:text-sm font-medium text-gray-900 group-hover:text-blue-600 transition-colors truncate">
                                  <%= school.name %>
                                </p>
                                <%= if school.address && school.address.street do %>
                                  <p class="text-xs text-gray-500 mt-0.5 truncate">
                                    <%= school.address.street %>
                                    <%= if school.address.zip_code do %>
                                      , <%= school.address.zip_code %> <%= String.slice(
                                        city.name,
                                        0,
                                        15
                                      ) %><%= if String.length(city.name) > 15, do: "..." %>
                                    <% end %>
                                  </p>
                                <% end %>
                              </div>
                              <div class="flex-shrink-0">
                                <svg
                                  class="w-3 h-3 sm:w-4 sm:h-4 text-gray-400 group-hover:text-blue-600 transition-colors mt-0.5"
                                  fill="none"
                                  stroke="currentColor"
                                  viewBox="0 0 24 24"
                                >
                                  <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M9 5l7 7-7 7"
                                  />
                                </svg>
                              </div>
                            </div>
                          </a>
                        </li>
                      <% end %>
                    </ul>
                    <!-- Expand/Collapse Button -->
                    <%= if length(schools) > 10 do %>
                      <div class="mt-2 sm:mt-4 pt-1.5 sm:pt-3 border-t border-gray-100">
                        <button
                          phx-click="toggle_city"
                          phx-value-city-id={city.id}
                          class="text-xs sm:text-sm font-medium text-blue-600 hover:text-blue-700 flex items-center w-full justify-center group py-1"
                          id={"toggle-city-#{city.id}"}
                        >
                          <%= if MapSet.member?(@expanded_cities, city.id) do %>
                            <span>Weniger anzeigen</span>
                          <% else %>
                            <span>Alle <%= length(schools) %> Schulen anzeigen</span>
                          <% end %>
                          <svg
                            class={"ml-0.5 sm:ml-1 w-3 h-3 sm:w-4 sm:h-4 transition-transform duration-200 #{if MapSet.member?(@expanded_cities, city.id), do: "rotate-180", else: ""}"}
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                              d="M19 9l-7 7-7-7"
                            />
                          </svg>
                        </button>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% else %>
            <.alert variant="info">
              Keine Städte mit Schulen gefunden für dieses Bundesland.
            </.alert>
          <% end %>
        </div>
      <% else %>
        <%= if length(@schools) > 0 do %>
          <div class="bg-white shadow-sm rounded-lg overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-200">
              <.heading level={2}>
                Suchergebnisse (<%= length(@schools) %> Schulen gefunden)
              </.heading>
            </div>
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                      phx-click="sort"
                      phx-value-field="name"
                    >
                      <div class="flex items-center space-x-1">
                        <span>Schulname</span>
                        <%= if @sort_by == :name do %>
                          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                            <%= if @sort_order == :asc do %>
                              <path d="M5 12l5-5 5 5H5z" />
                            <% else %>
                              <path d="M15 8l-5 5-5-5h10z" />
                            <% end %>
                          </svg>
                        <% end %>
                      </div>
                    </th>
                    <th
                      class="hidden sm:table-cell px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                      phx-click="sort"
                      phx-value-field="street"
                    >
                      <div class="flex items-center space-x-1">
                        <span>Straße</span>
                        <%= if @sort_by == :street do %>
                          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                            <%= if @sort_order == :asc do %>
                              <path d="M5 12l5-5 5 5H5z" />
                            <% else %>
                              <path d="M15 8l-5 5-5-5h10z" />
                            <% end %>
                          </svg>
                        <% end %>
                      </div>
                    </th>
                    <th
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                      phx-click="sort"
                      phx-value-field="zip_code"
                    >
                      <div class="flex items-center space-x-1">
                        <span>PLZ</span>
                        <%= if @sort_by == :zip_code do %>
                          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                            <%= if @sort_order == :asc do %>
                              <path d="M5 12l5-5 5 5H5z" />
                            <% else %>
                              <path d="M15 8l-5 5-5-5h10z" />
                            <% end %>
                          </svg>
                        <% end %>
                      </div>
                    </th>
                    <th
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                      phx-click="sort"
                      phx-value-field="city"
                    >
                      <div class="flex items-center space-x-1">
                        <span>Stadt</span>
                        <%= if @sort_by == :city do %>
                          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                            <%= if @sort_order == :asc do %>
                              <path d="M5 12l5-5 5 5H5z" />
                            <% else %>
                              <path d="M15 8l-5 5-5-5h10z" />
                            <% end %>
                          </svg>
                        <% end %>
                      </div>
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <%= for school <- @schools do %>
                    <tr class="hover:bg-gray-50">
                      <td class="px-6 py-4 whitespace-nowrap text-sm">
                        <a
                          href={"/ferien/d/schule/#{school.slug}"}
                          class="text-blue-600 hover:text-blue-900 font-medium"
                        >
                          <%= school.name %>
                        </a>
                      </td>
                      <td class="hidden sm:table-cell px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        <%= if school.address do %>
                          <%= school.address.street %>
                        <% else %>
                          <span class="text-gray-500">-</span>
                        <% end %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        <%= if school.address && school.address.zip_code do %>
                          <%= school.address.zip_code %>
                        <% else %>
                          <span class="text-gray-500">-</span>
                        <% end %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        <%= if school.parent_location do %>
                          <%= school.parent_location.name %>
                        <% else %>
                          <span class="text-gray-500">-</span>
                        <% end %>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        <% else %>
          <%= cond do %>
            <% @search_params["location"] == "" and @search_params["school_name"] == "" and @search_params["federal_state_id"] == "" -> %>
              <.alert variant="info">
                <%= format_number(@total_schools_in_system) %> Schulen gefunden. Bitte geben Sie genauere Suchkriterien ein.
              </.alert>
            <% true -> %>
              <.alert variant="info">
                Keine Schulen gefunden. Bitte versuchen Sie es mit anderen Suchkriterien.
              </.alert>
          <% end %>
        <% end %>
      <% end %>
    </div>
    """
  end
end
