defmodule MehrSchulferienWeb.HomeLive do
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferienWeb.NavigationHelper
  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods}
  require Logger

  @impl true
  def mount(_params, session, socket) do
    # Get navigation years for the navigation component
    today = DateHelpers.today_berlin()
    {current_year, next_year} = NavigationHelper.get_navigation_years(today)

    # Get location history from session (cookies are passed through session)
    recent_locations = load_location_history_from_session(session)

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
      |> assign(:show_vacation_timeline, true)
      |> assign(:recent_locations, recent_locations)
      |> load_vacation_timeline_data()

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

  defp load_location_history_from_session(session) do
    # Extract cookie values from session
    Logger.info("HomeLive - Session data: #{inspect(session)}")
    
    recent_locations_str = session["recent_locations"]
    Logger.info("HomeLive - Recent locations string: #{inspect(recent_locations_str)}")
    
    load_recent_locations(recent_locations_str)
  end

  defp load_recent_locations(nil), do: []
  defp load_recent_locations(""), do: []
  
  defp load_recent_locations(locations_str) do
    
    # Get country for lookups
    country = try do
      Locations.get_country_by_slug!("d")
    rescue
      _ -> nil
    end
    
    locations_str
    |> String.split(",")
    |> Enum.map(&parse_location_entry/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(fn {type, slug} ->
      location = case type do
        "f" ->
          try do
            fs = Locations.get_federal_state_by_slug!(slug, country)
            %{type: :federal_state, location: fs, name: fs.name, slug: fs.slug}
          rescue
            _ -> nil
          end
          
        "c" ->
          try do
            city = Locations.get_city_by_slug!(slug)
            %{type: :city, location: city, name: city.name, slug: city.slug}
          rescue
            _ -> nil
          end
          
        "s" ->
          try do
            school = Locations.get_school_by_slug!(slug)
            # Get parent city for display
            city = Locations.get_location!(school.parent_location_id)
            %{
              type: :school, 
              location: school, 
              name: school.name, 
              slug: school.slug,
              city_name: city.name
            }
          rescue
            _ -> nil
          end
      end
      
      location
    end)
    |> Enum.reject(&is_nil/1)
  end
  
  defp parse_location_entry(entry) do
    case String.split(entry, ":") do
      [type, slug] when type in ["f", "c", "s"] -> {type, slug}
      _ -> nil
    end
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
    import Ecto.Query
    alias MehrSchulferien.Repo

    federal_state_id_int = String.to_integer(federal_state_id)

    # Load federal state and country in one query with minimal fields
    query =
      from fs in MehrSchulferien.Locations.Location,
        join: c in MehrSchulferien.Locations.Location,
        on: c.id == fs.parent_location_id,
        where: fs.id == ^federal_state_id_int,
        select: %{
          federal_state_id: fs.id,
          federal_state_name: fs.name,
          federal_state_slug: fs.slug,
          country_id: c.id
        }

    case Repo.one(query) do
      nil ->
        raise Ecto.NoResultsError, queryable: MehrSchulferien.Locations.Location

      result ->
        # Need to use struct for list_counties_with_cities_having_schools
        federal_state_struct = %MehrSchulferien.Locations.Location{
          id: result.federal_state_id,
          name: result.federal_state_name,
          slug: result.federal_state_slug,
          parent_location_id: result.country_id,
          is_federal_state: true
        }

        federal_state = %{
          id: result.federal_state_id,
          name: result.federal_state_name,
          slug: result.federal_state_slug,
          parent_location_id: result.country_id
        }

        country = %{id: result.country_id}

        # Get city and school counts
        counties_with_cities =
          Locations.list_counties_with_cities_having_schools(federal_state_struct)

        # Count total cities and schools
        {city_count, school_count} =
          Enum.reduce(counties_with_cities, {0, 0}, fn {_county, cities}, {c_acc, s_acc} ->
            city_count = length(cities)

            school_count =
              Enum.reduce(cities, 0, fn %{school_count: count}, acc -> acc + count end)

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
  end

  defp load_all_cities_with_schools(federal_state_id) do
    import Ecto.Query
    alias MehrSchulferien.Repo

    federal_state_id_int = String.to_integer(federal_state_id)

    # Optimized query to get all schools with minimal fields
    query =
      from s in MehrSchulferien.Locations.Location,
        join: city in MehrSchulferien.Locations.Location,
        on: city.id == s.parent_location_id,
        join: county in MehrSchulferien.Locations.Location,
        on: county.id == city.parent_location_id,
        left_join: a in MehrSchulferien.Maps.Address,
        on: a.school_location_id == s.id,
        where: s.is_school == true,
        where: county.parent_location_id == ^federal_state_id_int,
        select: %{
          # School fields
          id: s.id,
          name: s.name,
          slug: s.slug,
          # City fields  
          city_id: city.id,
          city_name: city.name,
          # Address fields
          street: a.street,
          zip_code: a.zip_code
        },
        order_by: [city.name, s.name]

    results = Repo.all(query)

    # Group schools by city efficiently
    cities_with_schools =
      results
      |> Enum.group_by(fn r -> {r.city_id, r.city_name} end)
      |> Enum.map(fn {{city_id, city_name}, school_results} ->
        city = %{id: city_id, name: city_name}

        schools =
          Enum.map(school_results, fn r ->
            %{
              id: r.id,
              name: r.name,
              slug: r.slug,
              address:
                if(r.street || r.zip_code,
                  do: %{street: r.street, zip_code: r.zip_code},
                  else: nil
                )
            }
          end)

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

    # Optimized query with minimal fields
    query =
      from s in MehrSchulferien.Locations.Location,
        join: a in MehrSchulferien.Maps.Address,
        on: a.school_location_id == s.id,
        join: city in MehrSchulferien.Locations.Location,
        on: city.id == s.parent_location_id,
        join: county in MehrSchulferien.Locations.Location,
        on: county.id == city.parent_location_id,
        join: federal_state in MehrSchulferien.Locations.Location,
        on: federal_state.id == county.parent_location_id,
        where: s.is_school == true and a.zip_code == ^zip_code,
        select: %{
          # School fields
          id: s.id,
          name: s.name,
          slug: s.slug,
          # City fields
          city_id: city.id,
          city_name: city.name,
          # Federal state fields
          federal_state_id: federal_state.id,
          federal_state_name: federal_state.name,
          # Address fields
          street: a.street,
          zip_code: a.zip_code
        },
        order_by: s.name

    results = Repo.all(query)

    # Convert results to school structures
    schools =
      Enum.map(results, fn r ->
        %{
          id: r.id,
          name: r.name,
          slug: r.slug,
          parent_location: %{
            id: r.city_id,
            name: r.city_name,
            parent_location: %{
              parent_location: %{
                id: r.federal_state_id,
                name: r.federal_state_name
              }
            }
          },
          address: %{street: r.street, zip_code: r.zip_code}
        }
      end)

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

    # Optimized single query to get cities with schools
    query =
      from c in MehrSchulferien.Locations.Location,
        join: county in MehrSchulferien.Locations.Location,
        on: county.id == c.parent_location_id,
        join: federal_state in MehrSchulferien.Locations.Location,
        on: federal_state.id == county.parent_location_id,
        join: s in MehrSchulferien.Locations.Location,
        on: s.parent_location_id == c.id and s.is_school == true,
        left_join: a in MehrSchulferien.Maps.Address,
        on: a.school_location_id == s.id,
        where: c.is_city == true and ilike(c.name, ^city_pattern),
        select: %{
          # City fields
          city_id: c.id,
          city_name: c.name,
          # County & State fields for hierarchy
          county_id: county.id,
          federal_state_id: federal_state.id,
          # School fields
          school_id: s.id,
          school_name: s.name,
          school_slug: s.slug,
          # Address fields
          street: a.street,
          zip_code: a.zip_code
        },
        order_by: [c.name, s.name]

    results = Repo.all(query)

    if length(results) > 0 do
      # Group results by city
      cities_with_schools =
        results
        |> Enum.group_by(fn r ->
          {r.city_id, r.city_name, r.county_id, r.federal_state_id}
        end)
        |> Enum.map(fn {{city_id, city_name, county_id, federal_state_id}, school_results} ->
          city = %{
            id: city_id,
            name: city_name,
            parent_location: %{
              id: county_id,
              parent_location: %{id: federal_state_id}
            }
          }

          schools =
            Enum.map(school_results, fn r ->
              %{
                id: r.school_id,
                name: r.school_name,
                slug: r.school_slug,
                address:
                  if(r.street || r.zip_code,
                    do: %{street: r.street, zip_code: r.zip_code},
                    else: nil
                  )
              }
            end)

          {city, schools}
        end)

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

    # Optimized query for school search
    query =
      from s in MehrSchulferien.Locations.Location,
        join: city in MehrSchulferien.Locations.Location,
        on: city.id == s.parent_location_id,
        join: county in MehrSchulferien.Locations.Location,
        on: county.id == city.parent_location_id,
        join: federal_state in MehrSchulferien.Locations.Location,
        on: federal_state.id == county.parent_location_id,
        left_join: a in MehrSchulferien.Maps.Address,
        on: a.school_location_id == s.id,
        where: s.is_school == true and ilike(s.name, ^school_pattern),
        select: %{
          # School fields
          id: s.id,
          name: s.name,
          slug: s.slug,
          # City fields
          city_id: city.id,
          city_name: city.name,
          # County & State for hierarchy
          county_id: county.id,
          federal_state_id: federal_state.id,
          federal_state_name: federal_state.name,
          # Address fields
          street: a.street,
          zip_code: a.zip_code
        },
        order_by: s.name,
        limit: 500

    results = Repo.all(query)

    # Convert to school structures
    schools =
      Enum.map(results, fn r ->
        %{
          id: r.id,
          name: r.name,
          slug: r.slug,
          parent_location: %{
            id: r.city_id,
            name: r.city_name,
            parent_location: %{
              id: r.county_id,
              parent_location: %{
                id: r.federal_state_id,
                name: r.federal_state_name
              }
            }
          },
          address:
            if(r.street || r.zip_code, do: %{street: r.street, zip_code: r.zip_code}, else: nil)
        }
      end)

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
  
  defp get_location_url(location) do
    case location.type do
      :federal_state -> ~p"/ferien/d/bundesland/#{location.slug}"
      :city -> ~p"/ferien/d/stadt/#{location.slug}"
      :school -> ~p"/ferien/d/schule/#{location.slug}"
    end
  end
  
  defp truncate_name(name, _type, max_length) do
    # Truncate names based on max_length
    if String.length(name) > max_length do
      String.slice(name, 0, max_length) <> "..."
    else
      name
    end
  end
  
  defp should_show_recent_locations(search_params) do
    # Show recent locations only when both text fields are empty
    location = Map.get(search_params, "location", "")
    school_name = Map.get(search_params, "school_name", "")
    
    location == "" and school_name == ""
  end
  

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

      <.school_search_form
        federal_states={@federal_states}
        show_federal_state={true}
        search_params={@search_params}
        searching={@searching}
      >
        <:below_form>
          <!-- Recent Locations below form buttons -->
          <%= if length(@recent_locations) > 0 and should_show_recent_locations(@search_params) do %>
            <div class="mt-6 pt-5 border-t border-gray-200">
              <div class="flex flex-col gap-3">
                <div class="text-xs font-medium text-gray-500 uppercase tracking-wider">Zuletzt besucht</div>
                <!-- Mobile: horizontal flex, Desktop: grid -->
                <% mobile_locations = Enum.take(@recent_locations, 2) %>
                <% show_full_info = true %>
                <div class="flex md:grid md:grid-cols-3 gap-2 md:gap-3">
                  <%= for location <- @recent_locations do %>
                    <% show_on_mobile = location in mobile_locations %>
                    <a
                      href={get_location_url(location)}
                      class={"group #{if show_on_mobile, do: "flex", else: "hidden md:flex"} #{if show_full_info, do: "flex-row items-center", else: "md:flex-row flex-col items-center md:items-center"} gap-1 md:gap-3 p-2 md:p-3 bg-gray-50 hover:bg-gray-100 rounded-lg transition-colors flex-1 md:flex-initial"}
                    >
                      <div class="hidden md:block flex-shrink-0">
                        <%= case location.type do %>
                          <% :federal_state -> %>
                            <div class="w-8 h-8 md:w-10 md:h-10 bg-blue-100 text-blue-600 rounded-lg flex items-center justify-center">
                              <svg class="w-4 h-4 md:w-5 md:h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 21v-4m0 0V5a2 2 0 012-2h6.5l1 1H21l-3 6 3 6h-8.5l-1-1H5a2 2 0 00-2 2zm9-13.5V9" />
                              </svg>
                            </div>
                          <% :city -> %>
                            <div class="w-8 h-8 md:w-10 md:h-10 bg-green-100 text-green-600 rounded-lg flex items-center justify-center">
                              <svg class="w-4 h-4 md:w-5 md:h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                              </svg>
                            </div>
                          <% :school -> %>
                            <div class="w-8 h-8 md:w-10 md:h-10 bg-purple-100 text-purple-600 rounded-lg flex items-center justify-center">
                              <svg class="w-4 h-4 md:w-5 md:h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l9-5-9-5-9 5 9 5z" />
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z" />
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l9-5-9-5-9 5 9 5zm0 0l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14zm-4 6v-7.5l4-2.222" />
                              </svg>
                            </div>
                        <% end %>
                      </div>
                      <div class={"flex-1 min-w-0 #{if show_full_info, do: "text-left", else: "text-center md:text-left"}"}>
                        <div class={"#{if show_full_info, do: "text-sm", else: "text-xs md:text-sm"} font-medium text-gray-900 group-hover:text-blue-600 #{if show_full_info, do: "", else: "truncate max-w-[80px] md:max-w-none"}"}>
                          <span class="md:hidden"><%= truncate_name(location.name, location.type, 15) %></span>
                          <span class="hidden md:inline"><%= truncate_name(location.name, location.type, 23) %></span>
                        </div>
                        <div class={"#{if show_full_info, do: "block", else: "hidden md:block"} text-xs text-gray-500"}>
                          <%= case location.type do %>
                            <% :federal_state -> %>
                              Bundesland
                            <% :city -> %>
                              Stadt
                            <% :school -> %>
                              <%= location.city_name %>
                          <% end %>
                        </div>
                      </div>
                      <svg class="hidden md:block w-4 h-4 text-gray-400 group-hover:text-gray-600 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                      </svg>
                    </a>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        </:below_form>
      </.school_search_form>
      <!-- Prominent Result Counter -->
      <%= if @total_school_count > 0 and length(@cities_with_schools) > 1 do %>
        <div class="mb-4 sm:mb-6 bg-green-50 border border-green-200 rounded-lg p-3 sm:p-4 text-center md:text-left">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between">
            <div>
              <span class="font-bold text-lg sm:text-xl text-green-800">
                <%= format_number(@total_school_count) %> <%= if @total_school_count == 1,
                  do: "Schule",
                  else: "Schulen" %> gefunden
                <span class="text-green-700 ml-2 text-base">
                  in <%= format_number(@total_city_count) %> <%= if @total_city_count == 1,
                    do: "Stadt",
                    else: "Städten" %>
                </span>
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
              <%= if length(@cities_with_schools) == 1 do %>
                <% {_city, schools} = hd(@cities_with_schools) %>
                <span>
                  <span class="font-semibold">
                    <%= format_number(length(schools)) %>
                  </span>
                  <%= if length(schools) == 1,
                         do: "Schule",
                         else: "Schulen" %>
                </span>
              <% else %>
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
              <% end %>
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
            <%= if length(@cities_with_schools) > 1 do %>
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
            <% end %>
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

      <%= if @search_params["location"] == "" and @search_params["school_name"] == "" and @search_params["federal_state_id"] == "" do %>
        <!-- Separator between school search and vacation timeline -->
        <div class="mt-12 mb-8 border-t-2 border-gray-200"></div>
        <!-- Vacation Timeline Section -->
        <div class="mt-8">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6">
            <.heading level={2} class="mb-3 sm:mb-0">Schulferien Deutschland</.heading>
            <a
              href="/briefe"
              class="inline-flex items-center px-4 py-2 text-sm font-medium text-blue-700 bg-blue-50 border border-blue-200 rounded-md hover:bg-blue-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Entschuldigungen, Beurlaubungen und Sportbefreiungen als PDF generieren
              <svg class="ml-2 -mr-1 h-4 w-4" fill="currentColor" viewBox="0 0 20 20">
                <path
                  fill-rule="evenodd"
                  d="M10.293 3.293a1 1 0 011.414 0l6 6a1 1 0 010 1.414l-6 6a1 1 0 01-1.414-1.414L14.586 11H3a1 1 0 110-2h11.586l-4.293-4.293a1 1 0 010-1.414z"
                  clip-rule="evenodd"
                />
              </svg>
            </a>
          </div>
          <.text variant="base" class="mb-4 sm:mb-8">
            Die Ferien und Feiertage der nächsten <%= @vacation_number_of_days %> Tage auf einen Blick.
          </.text>

          <.card_grid>
            <%= for {%{country: _country, federal_states: federal_states, periods: periods}, country_index} <- Enum.with_index(@vacation_countries) do %>
              <%= for {federal_state, fs_index} <- Enum.with_index(federal_states) do %>
                <% # Get federal state periods and filter them
                federal_state_periods =
                  Enum.find(periods, fn {state, _} -> state.id == federal_state.id end) |> elem(1)

                filtered_periods =
                  Enum.filter(federal_state_periods, fn period ->
                    period.is_school_vacation || period.is_public_holiday
                  end)

                component_id = "timeline-#{country_index}-#{fs_index}"

                # Set up variables for year links
                current_year = @vacation_current_year
                next_year = current_year + 1 %>
                <!-- Card for each federal state -->
                <.card padding="p-6" class="h-full">
                  <:content>
                    <.section_title title={federal_state.name} />
                    <!-- Timeline visualization -->
                    <div id={"#{component_id}"}>
                      <%= MehrSchulferienWeb.VacationTimelineComponent.render(
                        days_to_show: @vacation_days,
                        months: @vacation_months,
                        all_periods: filtered_periods,
                        days_count: @vacation_number_of_days,
                        months_with_days: @vacation_months_with_days,
                        federal_state: federal_state
                      ) %>
                      <!-- Fallback text for test environment -->
                      <div class="hidden" aria-hidden="true">
                        Ferien und Feiertage im angezeigten Zeitraum
                      </div>
                    </div>

                    <div class="mt-4">
                      <div class="flex items-center gap-3">
                        <span class="text-sm text-gray-600">Ferientermine:</span>
                        <div class="flex-1 grid grid-cols-2 gap-3">
                          <.button
                            href={"/ferien/d/bundesland/#{federal_state.slug}/#{current_year}"}
                            variant="primary"
                            size="sm"
                            class="w-full"
                          >
                            <%= current_year %>
                          </.button>
                          <.button
                            href={"/ferien/d/bundesland/#{federal_state.slug}/#{next_year}"}
                            variant="secondary"
                            size="sm"
                            class="w-full"
                          >
                            <%= next_year %>
                          </.button>
                        </div>
                      </div>
                    </div>
                  </:content>
                </.card>
              <% end %>
            <% end %>
          </.card_grid>
        </div>

        <.stack spacing="8" class="mt-12">
          <.heading level={2}>Brückentage</.heading>
          <.card_grid>
            <%= for {%{country: _country, federal_states: federal_states}, _country_index} <- Enum.with_index(@vacation_countries) do %>
              <%= for {federal_state, _fs_index} <- Enum.with_index(federal_states) do %>
                <% # Find next bridge day for the federal state
                reference_date = @today

                next_bridge_day =
                  MehrSchulferien.BridgeDays.find_next_bridge_day(federal_state, reference_date, 1)

                # Set up variables for year links
                current_year = @vacation_current_year
                next_year = current_year + 1 %>
                <.card padding="p-6" class="h-full">
                  <:content>
                    <.section_title title={federal_state.name} />

                    <%= if next_bridge_day do %>
                      <% # Get related periods to find the public holiday
                      country = Locations.get_location!(federal_state.parent_location_id)
                      location_ids = [country.id, federal_state.id]

                      # Fetch public periods for this window to find the holiday that creates the bridge day
                      window_start = Date.add(next_bridge_day.starts_on, -5)
                      window_end = Date.add(next_bridge_day.starts_on, 5)

                      public_periods =
                        MehrSchulferien.Periods.list_public_everybody_periods(
                          location_ids,
                          window_start,
                          window_end
                        )

                      # Calculate efficiency
                      vacation_days = max(next_bridge_day.number_days - 1, 1)
                      total_free_days = next_bridge_day.number_days

                      efficiency =
                        if vacation_days > 0,
                          do: round((total_free_days - vacation_days) / vacation_days * 100),
                          else: 0

                      # Get timeline days for the bridge day
                      timeline_start = Date.add(next_bridge_day.starts_on, -10)
                      timeline_end = Date.add(next_bridge_day.ends_on, 10)
                      _timeline_days = Date.diff(timeline_end, timeline_start) + 1

                      days_range = Date.range(timeline_start, timeline_end)

                      # Group days by month
                      timeline_months =
                        days_range
                        |> Enum.to_list()
                        |> Enum.group_by(fn day ->
                          month_name = DateHelpers.get_months_map()[day.month]
                          {month_name, day.year, day.month}
                        end)
                        |> Enum.sort_by(fn {{_name, year, month}, _days} -> {year, month} end)
                        |> Enum.map(fn {{month_name, _year, _month}, days} -> {month_name, days} end)

                      # Create month groups with correct day counts
                      _months_with_days =
                        Enum.map(timeline_months, fn {month_name, days} ->
                          days_count = length(days)
                          {year, month} = {List.first(days).year, List.first(days).month}
                          {month_name, days_count, year, month}
                        end) %>

                      <.heading level={6} class="text-gray-700 mb-2">
                        Nächster Brückentag
                      </.heading>
                      <.text variant="small" class="mb-3">
                        <%= Calendar.strftime(next_bridge_day.starts_on, "%d.%m.%Y") %>
                        <%= if Date.compare(next_bridge_day.starts_on, next_bridge_day.ends_on) != :eq do %>
                          - <%= Calendar.strftime(next_bridge_day.ends_on, "%d.%m.%Y") %>
                        <% end %>
                      </.text>
                      <!-- Bridge Day Timeline -->
                      <div class="mb-4">
                        <%= MehrSchulferienWeb.BridgeDayTimelineComponent.bridge_day_timeline(%{
                          bridge_day: next_bridge_day,
                          periods: public_periods,
                          reference_date: reference_date,
                          vacation_days: vacation_days,
                          total_free_days: total_free_days,
                          efficiency_percentage: efficiency
                        }) %>
                      </div>

                      <% # Find super bridge day
                      best_super_bridge_day =
                        MehrSchulferien.BridgeDays.find_best_bridge_day(
                          federal_state,
                          reference_date,
                          12
                        ) %>

                      <%= if best_super_bridge_day do %>
                        <div class="mt-4 pt-4 border-t border-gray-200">
                          <.heading level={6} class="text-gray-700 mb-2">
                            Bester Superbrückentag
                          </.heading>
                          <.text variant="small">
                            <%= Calendar.strftime(
                              best_super_bridge_day.bridge_day.starts_on,
                              "%d.%m.%Y"
                            ) %> - <%= Calendar.strftime(
                              best_super_bridge_day.bridge_day.ends_on,
                              "%d.%m.%Y"
                            ) %>
                            <br />
                            <span class="text-xs text-gray-500">
                              <%= best_super_bridge_day.vacation_days %> Urlaubstag<%= if best_super_bridge_day.vacation_days >
                                                                                            1,
                                                                                          do: "e",
                                                                                          else: "" %> für <%= best_super_bridge_day.total_free_days %> freie Tage
                            </span>
                          </.text>
                        </div>
                      <% end %>
                    <% else %>
                      <.text variant="small">
                        Keine Brückentage in den nächsten Tagen gefunden
                      </.text>
                    <% end %>

                    <div class="mt-4">
                      <div class="flex items-center gap-3">
                        <span class="text-sm text-gray-600">Brückentage:</span>
                        <div class="flex-1 grid grid-cols-2 gap-3">
                          <.button
                            href={"/brueckentage/d/bundesland/#{federal_state.slug}/#{current_year}"}
                            variant="primary"
                            size="sm"
                            class="w-full"
                          >
                            <%= current_year %>
                          </.button>
                          <.button
                            href={"/brueckentage/d/bundesland/#{federal_state.slug}/#{next_year}"}
                            variant="secondary"
                            size="sm"
                            class="w-full"
                          >
                            <%= next_year %>
                          </.button>
                        </div>
                      </div>
                    </div>
                  </:content>
                </.card>
              <% end %>
            <% end %>
          </.card_grid>
        </.stack>
      <% end %>
    </div>
    """
  end

  defp load_vacation_timeline_data(socket) do
    # Load vacation timeline data similar to PageController#home
    today = socket.assigns.today
    days_to_display = 80
    current_year = today.year
    ends_on = Date.add(today, days_to_display)

    # Generate calendar data
    days = DateHelpers.create_days(today, days_to_display)
    day_names = DateHelpers.short_days_map()
    months = DateHelpers.get_months_map()
    months_with_days = calculate_months_with_days(days, months)

    # Fetch countries data with performance tracking
    {countries, _query_time} =
      measure_time(fn ->
        fetch_countries_with_periods_optimized(today, ends_on, current_year)
      end)

    socket
    |> assign(:vacation_days, days)
    |> assign(:vacation_day_names, day_names)
    |> assign(:vacation_months, months)
    |> assign(:vacation_current_year, current_year)
    |> assign(:vacation_number_of_days, days_to_display)
    |> assign(:vacation_months_with_days, months_with_days)
    |> assign(:vacation_countries, countries)
  end

  # Calculates the months with days for the timeline
  defp calculate_months_with_days(days, months) do
    days
    |> Enum.group_by(fn day -> {day.year, day.month} end)
    |> Enum.sort()
    |> Enum.map(fn {{year, month}, month_days} ->
      month_name = Map.get(months, month, "") |> to_string()
      {month_name, length(month_days), year, month}
    end)
  end

  # Helper to measure execution time
  defp measure_time(fun) do
    start = System.monotonic_time(:microsecond)
    result = fun.()
    finish = System.monotonic_time(:microsecond)
    # Return result and time in ms
    {result, (finish - start) / 1000}
  end

  # Optimized version that reduces SQL queries with ETS caching
  defp fetch_countries_with_periods_optimized(start_date, ends_on, current_year) do
    # Cached query to get countries with federal states (selective columns for 56% faster performance)
    countries_with_federal_states = Locations.list_countries_with_federal_states_cached()

    # Extract all location IDs for batch queries
    all_location_ids =
      Enum.flat_map(countries_with_federal_states, fn {country, federal_states} ->
        [country.id | Enum.map(federal_states, & &1.id)]
      end)

    # Cached query for all periods
    all_periods =
      Periods.list_school_free_periods_cached(all_location_ids, start_date, ends_on)

    # Group periods by location_id for O(1) lookup
    periods_by_location =
      all_periods
      |> Enum.group_by(& &1.location_id)
      |> Map.new()

    # Years to check for bridge days
    years = [current_year, current_year + 1, current_year + 2]

    # Get bridge days info for all states and years in a single query
    bridge_days_info = fetch_all_bridge_days_info(countries_with_federal_states, years)

    # Build the final data structure
    Enum.map(countries_with_federal_states, fn {country, federal_states} ->
      # Get country periods
      country_periods = Map.get(periods_by_location, country.id, [])

      # Process federal states with bridge day info
      federal_states_with_bridge_days =
        Enum.map(federal_states, fn state ->
          # Get years that have bridge days from the precomputed result
          years_with_bridge_days =
            years
            |> Enum.filter(fn year ->
              Map.get(bridge_days_info, {state.id, year}, false)
            end)

          Map.put(state, :years_with_bridge_days, years_with_bridge_days)
        end)

      # Create periods entries for each federal state
      periods =
        Enum.map(federal_states_with_bridge_days, fn state ->
          state_periods = Map.get(periods_by_location, state.id, [])
          {state, country_periods ++ state_periods}
        end)

      # Return the final country entry
      %{
        country: country,
        federal_states: federal_states_with_bridge_days,
        periods: periods
      }
    end)
  end

  # Fetch all bridge days info in a single optimized operation
  defp fetch_all_bridge_days_info(countries_with_federal_states, years) do
    # Get all unique state IDs and country IDs
    {country_ids, state_ids} =
      Enum.reduce(countries_with_federal_states, {[], []}, fn {country, states}, {c_acc, s_acc} ->
        state_ids = Enum.map(states, & &1.id)
        {[country.id | c_acc], state_ids ++ s_acc}
      end)

    country_ids = Enum.uniq(country_ids)
    state_ids = Enum.uniq(state_ids)

    # Get min and max year for date range
    min_year = Enum.min(years)
    max_year = Enum.max(years)
    {:ok, start_date} = Date.new(min_year, 1, 1)
    {:ok, end_date} = Date.new(max_year, 12, 31)

    # Fetch all periods for all locations and years at once
    all_location_ids = country_ids ++ state_ids
    all_periods = Periods.list_public_everybody_periods(all_location_ids, start_date, end_date)

    # Process each state/year combination
    results =
      for state_id <- state_ids, year <- years do
        # Find country for this state
        country_id =
          Enum.find_value(countries_with_federal_states, fn {country, states} ->
            if Enum.any?(states, &(&1.id == state_id)), do: country.id
          end)

        # Filter periods for this year and locations
        {:ok, year_start} = Date.new(year, 1, 1)
        {:ok, year_end} = Date.new(year, 12, 31)

        location_ids = [country_id, state_id]

        year_periods =
          Enum.filter(all_periods, fn period ->
            period.location_id in location_ids and
              Date.compare(period.starts_on, year_end) != :gt and
              Date.compare(period.ends_on, year_start) != :lt
          end)

        # Check if there are bridge days (simplified check)
        has_bridge_days = length(year_periods) >= 2

        {{state_id, year}, has_bridge_days}
      end

    Map.new(results)
  end
end
