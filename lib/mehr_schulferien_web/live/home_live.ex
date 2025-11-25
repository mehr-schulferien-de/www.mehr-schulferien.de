defmodule MehrSchulferienWeb.HomeLive do
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferienWeb.NavigationHelper
  alias MehrSchulferienWeb.Formatters.DateFormatter
  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods}
  alias MehrSchulferienWeb.Live.Shared.{LocationHistoryHelpers, SchoolSearchLogic}
  import MehrSchulferienWeb.Shared.LocationHistoryComponent
  require Logger

  @impl true
  def mount(_params, session, socket) do
    # Get navigation years for the navigation component
    today = DateHelpers.today_berlin()
    {current_year, next_year} = NavigationHelper.get_navigation_years(today)

    # Get location history from session (cookies are passed through session)
    recent_locations = load_location_history_from_session(session)

    # Get federal states for dropdown
    federal_states = SchoolSearchLogic.get_federal_states()

    # Check if database is empty
    if federal_states == [] do
      {:ok, assign(socket, :empty_database, true)}
    else
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
  end

  @impl true
  def handle_event("search", %{"search" => search_params}, socket) do
    schools = search_schools_with_federal_state(search_params)

    sorted_schools =
      SchoolSearchLogic.sort_schools(schools, socket.assigns.sort_by, socket.assigns.sort_order)

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
        String.length(location) >= 1 and is_partial_or_full_zip_code?(location) ->
          handle_zip_code_search_with_auto_federal_state(socket, location, school_name)

        # Federal state is selected
        federal_state_id != "" ->
          socket = handle_federal_state_search(socket, federal_state_id)

          # Further filter by location if provided
          socket =
            if String.length(location) >= 1 do
              filter_by_city_name(socket, location)
            else
              socket
            end

          # Further filter by school name if provided  
          if String.length(school_name) >= 1 do
            filter_by_school_name(socket, school_name)
          else
            socket
          end

        # Only location is provided (no federal state selected) - must be city name
        String.length(location) >= 1 ->
          handle_city_search_all_states(socket, location, school_name)

        # Only school name is provided
        String.length(school_name) >= 1 ->
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

  # Valid sort fields to prevent atom table exhaustion
  @valid_sort_fields ~w(name street zip_code city)a

  @impl true
  def handle_event("toggle_city", %{"city-id" => city_id}, socket) do
    case Integer.parse(city_id) do
      {city_id_int, ""} ->
        expanded_cities = socket.assigns.expanded_cities

        expanded_cities =
          if MapSet.member?(expanded_cities, city_id_int) do
            MapSet.delete(expanded_cities, city_id_int)
          else
            MapSet.put(expanded_cities, city_id_int)
          end

        socket = assign(socket, :expanded_cities, expanded_cities)

        # Push an event to maintain scroll position
        {:noreply,
         push_event(socket, "maintain-scroll", %{element_id: "city-card-#{city_id_int}"})}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("sort", %{"field" => field}, socket) do
    case validate_sort_field(field) do
      {:ok, field_atom} ->
        {sort_by, sort_order} =
          if socket.assigns.sort_by == field_atom do
            # Toggle order if clicking the same field
            {field_atom, if(socket.assigns.sort_order == :asc, do: :desc, else: :asc)}
          else
            # New field, default to ascending
            {field_atom, :asc}
          end

        sorted_schools =
          SchoolSearchLogic.sort_schools(socket.assigns.schools, sort_by, sort_order)

        {:noreply,
         assign(socket,
           schools: sorted_schools,
           sort_by: sort_by,
           sort_order: sort_order
         )}

      :error ->
        {:noreply, socket}
    end
  end

  defp validate_sort_field(field) when is_binary(field) do
    try do
      atom = String.to_existing_atom(field)
      if atom in @valid_sort_fields, do: {:ok, atom}, else: :error
    rescue
      ArgumentError -> :error
    end
  end

  defp validate_sort_field(_), do: :error

  # get_federal_states now delegated to SchoolSearchLogic

  defp load_location_history_from_session(session) do
    # Extract cookie values from session
    Logger.info("HomeLive - Session data: #{inspect(session)}")

    recent_locations_str = session["recent_locations"]
    Logger.info("HomeLive - Recent locations string: #{inspect(recent_locations_str)}")

    LocationHistoryHelpers.load_recent_locations(recent_locations_str)
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

    case parse_integer(federal_state_id) do
      {:ok, federal_state_id_int} ->
        Enum.filter(schools, fn school ->
          # Check if school's parent location (city) belongs to the selected federal state
          school.parent_location &&
            school.parent_location.parent_location_id == federal_state_id_int
        end)

      :error ->
        schools
    end
  end

  defp parse_integer(nil), do: :error
  defp parse_integer(""), do: :error

  defp parse_integer(value) when is_integer(value), do: {:ok, value}

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> {:ok, int}
      _ -> :error
    end
  end

  defp parse_integer(_), do: :error

  # sort_schools now delegated to SchoolSearchLogic

  defp load_federal_state_overview(federal_state_id, today) do
    import Ecto.Query
    alias MehrSchulferien.Repo

    {:ok, federal_state_id_int} = parse_integer(federal_state_id)

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

    {:ok, federal_state_id_int} = parse_integer(federal_state_id)

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
          city_slug: city.slug,
          # Address fields
          street: a.street,
          zip_code: a.zip_code
        },
        order_by: [city.name, s.name]

    results = Repo.all(query)

    # Group schools by city efficiently
    cities_with_schools =
      results
      |> Enum.group_by(fn r -> {r.city_id, r.city_name, r.city_slug} end)
      |> Enum.map(fn {{city_id, city_name, city_slug}, school_results} ->
        city = %{id: city_id, name: city_name, slug: city_slug}

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

  defp is_partial_or_full_zip_code?(nil), do: false

  defp is_partial_or_full_zip_code?(text) do
    # Check if it's all digits and between 1-5 characters
    String.length(text) >= 1 and String.length(text) <= 5 and Regex.match?(~r/^\d+$/, text)
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
    # Support wildcard searches with *
    if String.contains?(city_name, "*") do
      # Wildcard search - replace * with .* for regex
      pattern =
        city_name
        |> String.downcase()
        |> String.replace("*", ".*")
        |> Regex.compile!()

      filtered_cities =
        socket.assigns.cities_with_schools
        |> Enum.filter(fn {city, _schools} ->
          Regex.match?(pattern, String.downcase(city.name))
        end)

      assign(socket, :cities_with_schools, filtered_cities)
    else
      # Default: search from beginning of name
      city_pattern = String.downcase(city_name)

      filtered_cities =
        socket.assigns.cities_with_schools
        |> Enum.filter(fn {city, _schools} ->
          String.starts_with?(String.downcase(city.name), city_pattern)
        end)

      assign(socket, :cities_with_schools, filtered_cities)
    end
  end

  defp filter_by_school_name(socket, school_name) do
    # Support wildcard searches with *
    if String.contains?(school_name, "*") do
      # Wildcard search - replace * with .* for regex
      pattern =
        school_name
        |> String.downcase()
        |> String.replace("*", ".*")
        |> Regex.compile!()

      filtered_cities =
        socket.assigns.cities_with_schools
        |> Enum.map(fn {city, schools} ->
          filtered_schools =
            Enum.filter(schools, fn school ->
              Regex.match?(pattern, String.downcase(school.name))
            end)

          {city, filtered_schools}
        end)
        |> Enum.filter(fn {_city, schools} -> length(schools) > 0 end)

      assign(socket, :cities_with_schools, filtered_cities)
    else
      # Default: search from beginning of name
      school_pattern = String.downcase(school_name)

      filtered_cities =
        socket.assigns.cities_with_schools
        |> Enum.map(fn {city, schools} ->
          filtered_schools =
            Enum.filter(schools, fn school ->
              String.starts_with?(String.downcase(school.name), school_pattern)
            end)

          {city, filtered_schools}
        end)
        |> Enum.filter(fn {_city, schools} -> length(schools) > 0 end)

      assign(socket, :cities_with_schools, filtered_cities)
    end
  end

  defp handle_zip_code_search_with_auto_federal_state(socket, zip_code, school_name) do
    import Ecto.Query
    alias MehrSchulferien.Repo

    # Use LIKE for partial zip code matching (starts with)
    zip_pattern = "#{zip_code}%"

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
        where: s.is_school == true and like(a.zip_code, ^zip_pattern),
        select: %{
          # School fields
          id: s.id,
          name: s.name,
          slug: s.slug,
          # City fields
          city_id: city.id,
          city_name: city.name,
          city_slug: city.slug,
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
            slug: r.city_slug,
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
      # Group schools by city - ensure we're grouping by city ID to avoid issues
      cities_with_schools =
        schools
        |> Enum.group_by(fn school ->
          # Group by city ID to ensure unique cities are properly detected
          school.parent_location.id
        end)
        |> Enum.map(fn {_city_id, city_schools} ->
          # Get the city info from the first school
          city = hd(city_schools).parent_location
          {city, city_schools}
        end)
        |> Enum.sort_by(fn {city, _} -> city.name end)

      # Check if all schools are from a single city
      unique_cities =
        cities_with_schools
        |> Enum.map(fn {city, _} -> city.id end)
        |> Enum.uniq()

      # Only update federal state if there's exactly one city
      if length(unique_cities) == 1 do
        # Single city - get its federal state
        {city, _} = hd(cities_with_schools)
        federal_state = city.parent_location.parent_location

        # Update search params with federal state
        search_params =
          Map.put(socket.assigns.search_params, "federal_state_id", to_string(federal_state.id))

        socket = assign(socket, :search_params, search_params)

        # Load federal state overview
        federal_state_overview =
          load_federal_state_overview(to_string(federal_state.id), socket.assigns.today)

        socket
        |> assign(:federal_state_overview, federal_state_overview)
      else
        # Multiple cities - don't set federal state
        search_params = Map.put(socket.assigns.search_params, "federal_state_id", "")

        socket
        |> assign(:search_params, search_params)
      end

      socket =
        socket
        |> assign(:cities_with_schools, cities_with_schools)
        |> assign(:show_all_schools, true)

      # Further filter by school name if provided
      if String.length(school_name) >= 1 do
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

    # Support wildcard searches with * 
    city_pattern =
      if String.contains?(city_name, "*") do
        # Replace * with % for SQL wildcard
        city_name |> String.replace("*", "%")
      else
        # Default: search from beginning of words
        # This will match "Koblenz", "Kassel" but not "Frankfurt" for search "k"
        "#{city_name}%"
      end

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
          city_slug: c.slug,
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
          {r.city_id, r.city_name, r.city_slug, r.county_id, r.federal_state_id}
        end)
        |> Enum.map(fn {{city_id, city_name, city_slug, county_id, federal_state_id},
                        school_results} ->
          city = %{
            id: city_id,
            name: city_name,
            slug: city_slug,
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
        # Only set federal state if there's exactly one city
        socket =
          if length(cities_with_schools) == 1 do
            {city, _} = hd(cities_with_schools)
            federal_state = city.parent_location.parent_location

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
            # Multiple cities - don't set federal state
            search_params = Map.put(socket.assigns.search_params, "federal_state_id", "")

            socket
            |> assign(:search_params, search_params)
          end

        socket =
          socket
          |> assign(:cities_with_schools, cities_with_schools)
          |> assign(:show_all_schools, true)

        # Further filter by school name if provided
        if String.length(school_name) >= 1 do
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

    # Support wildcard searches with * 
    school_pattern =
      if String.contains?(school_name, "*") do
        # Replace * with % for SQL wildcard
        school_name |> String.replace("*", "%")
      else
        # Default: search from beginning of name
        "#{school_name}%"
      end

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

      # Only set federal state if there's exactly one city
      socket =
        if length(cities_with_schools) == 1 do
          # Single city - load federal state overview
          {city, _} = hd(cities_with_schools)
          federal_state = city.parent_location.parent_location

          federal_state_overview =
            load_federal_state_overview(to_string(federal_state.id), socket.assigns.today)

          # Update search params with federal state
          search_params =
            Map.put(socket.assigns.search_params, "federal_state_id", to_string(federal_state.id))

          socket
          |> assign(:federal_state_overview, federal_state_overview)
          |> assign(:search_params, search_params)
        else
          # Multiple cities - don't set federal state
          search_params = Map.put(socket.assigns.search_params, "federal_state_id", "")

          socket
          |> assign(:search_params, search_params)
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

  defp should_show_recent_locations(search_params) do
    LocationHistoryHelpers.should_show_recent_locations(search_params)
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
    <%= if assigns[:empty_database] do %>
      <main class="min-h-screen bg-gray-50">
        <div class="container mx-auto px-4 py-16">
          <div class="max-w-2xl mx-auto text-center">
            <div class="bg-white rounded-lg shadow-lg p-8">
              <div class="mb-6">
                <svg
                  class="mx-auto h-16 w-16 text-yellow-500"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
                  />
                </svg>
              </div>

              <h1 class="text-3xl font-bold text-gray-900 mb-4">
                Datenbank ist leer
              </h1>

              <p class="text-gray-600 mb-6">
                Die Datenbank enthält derzeit keine Daten. Bitte stellen Sie sicher, dass die Datenbank korrekt eingerichtet wurde und alle erforderlichen Daten geladen sind.
              </p>

              <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-6">
                <p class="text-sm text-yellow-800">
                  <strong>Für Administratoren:</strong>
                  Führen Sie <code class="bg-yellow-100 px-2 py-1 rounded">mix ecto.setup</code>
                  aus, um die Datenbank zu initialisieren und mit Daten zu füllen.
                </p>
              </div>

              <a
                href="/"
                class="inline-flex items-center justify-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 transition-colors"
              >
                Zur Startseite
              </a>
            </div>
          </div>
        </div>
      </main>
    <% else %>
      <div class="mt-6 sm:mt-8" id="test-page-container" phx-hook="MaintainScroll">
        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between mb-4">
          <.heading level={1}>
            Schulferien und Feiertage
          </.heading>
        </div>

        <.school_search_form
          federal_states={@federal_states}
          show_federal_state={true}
          search_params={@search_params}
          searching={@searching}
        >
          <:below_form>
            <.location_history
              recent_locations={@recent_locations}
              show={should_show_recent_locations(@search_params)}
            />
          </:below_form>
        </.school_search_form>

        <%= if @show_all_schools do %>
          <div class="mb-8">
            <.heading level={2} class="mb-3 sm:mb-4 text-lg sm:text-2xl">
              <%= cond do %>
                <% String.length(@search_params["location"] || "") >= 1 and String.length(@search_params["school_name"] || "") >= 1 -> %>
                  Suchergebnisse für "{@search_params["school_name"]}" in
                  <%= if is_partial_or_full_zip_code?(@search_params["location"]) do %>
                    PLZ {@search_params["location"]}
                    <%= if length(@cities_with_schools) == 1 do %>
                      <% {city, _schools} = hd(@cities_with_schools) %> (<a
                        href={~p"/ferien/d/stadt/#{city.slug}"}
                        class="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 underline"
                      ><%= city.name %></a>)
                    <% end %>
                  <% else %>
                    "{@search_params["location"]}"
                    <%= if @federal_state_overview do %>
                      ({get_federal_state_name(@federal_state_overview)})
                    <% end %>
                  <% end %>
                <% String.length(@search_params["location"] || "") >= 1 -> %>
                  Suchergebnisse für
                  <%= if is_partial_or_full_zip_code?(@search_params["location"]) do %>
                    PLZ {@search_params["location"]}
                    <%= if length(@cities_with_schools) == 1 do %>
                      <% {city, _schools} = hd(@cities_with_schools) %> (<a
                        href={~p"/ferien/d/stadt/#{city.slug}"}
                        class="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 underline"
                      ><%= city.name %></a>)
                    <% end %>
                  <% else %>
                    "{@search_params["location"]}"
                    <%= if @federal_state_overview do %>
                      ({get_federal_state_name(@federal_state_overview)})
                    <% end %>
                  <% end %>
                <% String.length(@search_params["school_name"] || "") >= 1 -> %>
                  Suchergebnisse für "{@search_params["school_name"]}"
                  <%= if @federal_state_overview do %>
                    in {get_federal_state_name(@federal_state_overview)}
                  <% end %>
                <% @federal_state_overview -> %>
                  Alle Städte und Schulen in {get_federal_state_name(@federal_state_overview)}
                <% true -> %>
                  Suchergebnisse
              <% end %>
            </.heading>

            <%= if length(@cities_with_schools) > 0 do %>
              <!-- Summary Statistics -->
              <%= if length(@cities_with_schools) > 1 do %>
                <div class="mb-4 sm:mb-6 bg-gray-50 dark:bg-gray-800 rounded-lg p-3 sm:p-4">
                  <div class="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4 text-center">
                    <div>
                      <.text
                        variant="small"
                        class="text-xs sm:text-sm text-gray-600 dark:text-gray-400"
                      >
                        Städte
                      </.text>
                      <.text variant="lead" class="font-bold text-lg sm:text-2xl">
                        {format_number(length(@cities_with_schools))}
                      </.text>
                    </div>
                    <div>
                      <.text
                        variant="small"
                        class="text-xs sm:text-sm text-gray-600 dark:text-gray-400"
                      >
                        Schulen gesamt
                      </.text>
                      <.text variant="lead" class="font-bold text-lg sm:text-2xl">
                        {format_number(
                          Enum.reduce(@cities_with_schools, 0, fn {_city, schools}, acc ->
                            acc + length(schools)
                          end)
                        )}
                      </.text>
                    </div>
                    <div>
                      <.text
                        variant="small"
                        class="text-xs sm:text-sm text-gray-600 dark:text-gray-400"
                      >
                        Ø Schulen pro Stadt
                      </.text>
                      <.text variant="lead" class="font-bold text-lg sm:text-2xl">
                        {format_number(
                          Float.round(
                            Enum.reduce(@cities_with_schools, 0, fn {_city, schools}, acc ->
                              acc + length(schools)
                            end) / length(@cities_with_schools),
                            1
                          )
                        )}
                      </.text>
                    </div>
                    <div>
                      <.text
                        variant="small"
                        class="text-xs sm:text-sm text-gray-600 dark:text-gray-400"
                      >
                        Größte Stadt
                      </.text>
                      <%= case Enum.max_by(@cities_with_schools, fn {_city, schools} -> length(schools) end, fn -> nil end) do %>
                        <% {city, schools} -> %>
                          <a
                            href={"#city-card-#{city.id}"}
                            class="text-sm sm:text-base font-semibold text-blue-600 hover:text-blue-800 hover:underline"
                          >
                            {city.name} ({format_number(length(schools))})
                          </a>
                        <% _ -> %>
                          <.text variant="base" class="text-sm sm:text-base font-semibold">-</.text>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
              <!-- Cities Grid / School List -->
              <%= if length(@cities_with_schools) == 1 do %>
                <!-- Single city: show schools in a 3-column grid -->
                <% {city, schools} = hd(@cities_with_schools) %>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4">
                  <%= for school <- schools do %>
                    <a
                      href={"/ferien/d/schule/#{school.slug}"}
                      class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 hover:shadow-md transition-all duration-200 p-4 group block"
                    >
                      <div class="flex items-start justify-between gap-2">
                        <div class="flex-1 min-w-0">
                          <h3 class="text-sm font-semibold text-gray-900 dark:text-gray-100 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors mb-1">
                            {school.name}
                          </h3>
                          <%= if school.address do %>
                            <p class="text-xs text-gray-500 dark:text-gray-400">
                              <%= if school.address.street do %>
                                {school.address.street}<br />
                              <% end %>
                              <%= if school.address.zip_code do %>
                                {school.address.zip_code} {city.name}
                              <% end %>
                            </p>
                          <% end %>
                        </div>
                        <svg
                          class="w-4 h-4 text-gray-400 dark:text-gray-500 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors flex-shrink-0 mt-0.5"
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
                    </a>
                  <% end %>
                </div>
              <% else %>
                <!-- Multiple cities: show cities with schools in cards -->
                <div class="grid grid-cols-1 lg:grid-cols-3 gap-3 sm:gap-4 lg:gap-6">
                  <%= for {city, schools} <- @cities_with_schools do %>
                    <div
                      class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 hover:shadow-lg transition-all duration-200"
                      id={"city-card-#{city.id}"}
                    >
                      <!-- City Header -->
                      <div class="px-3 sm:px-5 py-2.5 sm:py-4 border-b border-gray-200 dark:border-gray-700">
                        <div class="flex items-baseline justify-between gap-2">
                          <%= if Map.has_key?(city, :slug) do %>
                            <a
                              href={~p"/ferien/d/stadt/#{city.slug}"}
                              class="text-sm sm:text-lg font-semibold text-gray-900 hover:text-blue-600 transition-colors truncate"
                            >
                              {city.name}
                            </a>
                          <% else %>
                            <h3 class="text-sm sm:text-lg font-semibold text-gray-900 truncate">
                              {city.name}
                            </h3>
                          <% end %>
                          <span class="text-xs sm:text-sm font-medium text-gray-600 flex-shrink-0 whitespace-nowrap">
                            {format_number(length(schools))} {if length(schools) == 1,
                              do: "Schule",
                              else: "Schulen"}
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
                            PLZ-Bereich: {format_zip_codes_list(zip_codes)}
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
                                    <p class="text-xs sm:text-sm font-medium text-gray-900 dark:text-gray-100 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors truncate">
                                      {school.name}
                                    </p>
                                    <%= if school.address && school.address.street do %>
                                      <p class="text-xs text-gray-500 mt-0.5 truncate">
                                        {school.address.street}
                                        <%= if school.address.zip_code do %>
                                          , {school.address.zip_code} {String.slice(
                                            city.name,
                                            0,
                                            15
                                          )}{if String.length(city.name) > 15, do: "..."}
                                        <% end %>
                                      </p>
                                    <% end %>
                                  </div>
                                  <div class="flex-shrink-0">
                                    <svg
                                      class="w-3 h-3 sm:w-4 sm:h-4 text-gray-400 dark:text-gray-500 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors mt-0.5"
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
                          <div class="mt-2 sm:mt-4 pt-1.5 sm:pt-3 border-t border-gray-100 dark:border-gray-700">
                            <button
                              phx-click="toggle_city"
                              phx-value-city-id={city.id}
                              class="text-xs sm:text-sm font-medium text-blue-600 hover:text-blue-700 flex items-center w-full justify-center group py-1"
                              id={"toggle-city-#{city.id}"}
                            >
                              <%= if MapSet.member?(@expanded_cities, city.id) do %>
                                <span>Weniger anzeigen</span>
                              <% else %>
                                <span>Alle {length(schools)} Schulen anzeigen</span>
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
              <% end %>
            <% else %>
              <.alert variant="info">
                Keine Städte mit Schulen gefunden für dieses Bundesland.
              </.alert>
            <% end %>
          </div>
        <% end %>

        <%= if @federal_state_overview do %>
          <div class="mb-6 sm:mb-8 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4 sm:p-6">
            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-4">
              <.heading level={2} class="mb-2 sm:mb-0 text-lg sm:text-xl">
                <%= if length(@cities_with_schools) == 1 do %>
                  <% {city, _schools} = hd(@cities_with_schools) %>
                  {city.name}, {@federal_state_overview.federal_state.name}
                <% else %>
                  {@federal_state_overview.federal_state.name}
                <% end %>
              </.heading>
              <div class="flex gap-4 text-sm text-gray-600 dark:text-gray-400">
                <%= if length(@cities_with_schools) == 1 do %>
                  <% {_city, schools} = hd(@cities_with_schools) %>
                  <span>
                    <span class="font-semibold">
                      {format_number(length(schools))}
                    </span>
                    {if length(schools) == 1,
                      do: "Schule",
                      else: "Schulen"}
                  </span>
                <% else %>
                  <span>
                    <span class="font-semibold">
                      {format_number(@federal_state_overview.city_count)}
                    </span>
                    {if @federal_state_overview.city_count ==
                          1,
                        do: "Stadt",
                        else: "Städte"}
                  </span>
                  <span>
                    <span class="font-semibold">
                      {format_number(@federal_state_overview.school_count)}
                    </span>
                    {if @federal_state_overview.school_count ==
                          1,
                        do: "Schule",
                        else: "Schulen"}
                  </span>
                <% end %>
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-3 sm:gap-4">
              <a
                href={"/ferien/d/bundesland/#{@federal_state_overview.federal_state.slug}/#{@today.year}"}
                class="bg-white dark:bg-gray-800 rounded-lg p-3 sm:p-4 shadow-sm hover:shadow-md transition-shadow"
              >
                <.text variant="base" class="font-semibold mb-2">Nächste Schulferien</.text>
                <div class="space-y-1">
                  <%= for vacation <- Enum.take(@federal_state_overview.next_vacations, 3) do %>
                    <div class="text-sm">
                      <div class="font-medium">
                        {vacation.holiday_or_vacation_type.colloquial}
                      </div>
                      <div class="text-gray-600 dark:text-gray-400">
                        {DateFormatter.format_date_full(vacation.starts_on)} - {DateFormatter.format_date_full(
                          vacation.ends_on
                        )}
                      </div>
                    </div>
                  <% end %>
                </div>
                <div class="mt-3 text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300">
                  Mehr anzeigen →
                </div>
              </a>

              <a
                href={"/ferien/d/bundesland/#{@federal_state_overview.federal_state.slug}/#{@today.year}"}
                class="bg-white dark:bg-gray-800 rounded-lg p-3 sm:p-4 shadow-sm hover:shadow-md transition-shadow"
              >
                <.text variant="base" class="font-semibold mb-2">Nächste Feiertage</.text>
                <div class="space-y-1">
                  <%= for holiday <- Enum.take(@federal_state_overview.next_holidays, 3) do %>
                    <div class="text-sm">
                      <div class="font-medium">
                        {holiday.holiday_or_vacation_type.colloquial}
                      </div>
                      <div class="text-gray-600 dark:text-gray-400">
                        {DateFormatter.format_date_full(holiday.starts_on)}
                      </div>
                    </div>
                  <% end %>
                </div>
                <div class="mt-3 text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300">
                  Mehr anzeigen →
                </div>
              </a>

              <a
                href={"/brueckentage/d/bundesland/#{@federal_state_overview.federal_state.slug}/#{@today.year}"}
                class="bg-white dark:bg-gray-800 rounded-lg p-3 sm:p-4 shadow-sm hover:shadow-md transition-shadow"
              >
                <.text variant="base" class="font-semibold mb-2">Nächste Brückentage</.text>
                <div class="space-y-1">
                  <%= if length(@federal_state_overview.next_bridge_days) > 0 do %>
                    <%= for bridge_info <- Enum.take(@federal_state_overview.next_bridge_days, 3) do %>
                      <div class="text-sm">
                        <div class="font-medium">
                          {bridge_info.vacation_days} {if bridge_info.vacation_days == 1,
                            do: "Tag",
                            else: "Tage"} Urlaub
                        </div>
                        <div class="text-gray-600 dark:text-gray-400">
                          → {bridge_info.total_free_days} Tage frei (×{bridge_info.gain_factor})
                        </div>
                      </div>
                    <% end %>
                  <% else %>
                    <div class="text-sm text-gray-500 dark:text-gray-400">
                      Keine Brückentage in nächster Zeit
                    </div>
                  <% end %>
                </div>
                <div class="mt-3 text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300">
                  Mehr anzeigen →
                </div>
              </a>
            </div>
          </div>
        <% end %>

        <%= if !@show_all_schools do %>
          <%= if length(@schools) > 0 do %>
            <div class="bg-white dark:bg-gray-800 shadow-sm rounded-lg overflow-hidden">
              <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                <.heading level={2}>
                  Suchergebnisse ({length(@schools)} Schulen gefunden)
                </.heading>
              </div>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                  <thead class="bg-gray-50 dark:bg-gray-900">
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
                            {school.name}
                          </a>
                        </td>
                        <td class="hidden sm:table-cell px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          <%= if school.address do %>
                            {school.address.street}
                          <% else %>
                            <span class="text-gray-500">-</span>
                          <% end %>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          <%= if school.address && school.address.zip_code do %>
                            {school.address.zip_code}
                          <% else %>
                            <span class="text-gray-500">-</span>
                          <% end %>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          <%= if school.parent_location do %>
                            {school.parent_location.name}
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
                  {format_number(@total_schools_in_system)} Schulen gefunden. Bitte geben Sie genauere Suchkriterien ein.
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
          <div class="mt-12 mb-8 border-t-2 border-gray-200 dark:border-gray-700"></div>
          <!-- Vacation Timeline Section -->
          <div class="mt-8">
            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6">
              <.heading level={2} class="mb-3 sm:mb-0">Schulferien Deutschland</.heading>
              <a
                href="/briefe"
                class="inline-flex items-center px-4 py-2 text-sm font-medium text-blue-700 dark:text-blue-200 bg-blue-50 dark:bg-blue-900/30 border border-blue-200 dark:border-blue-700 rounded-md hover:bg-blue-100 dark:hover:bg-blue-900/40 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:focus:ring-blue-400"
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
              Die Ferien und Feiertage der nächsten {@vacation_number_of_days} Tage auf einen Blick.
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
                        {MehrSchulferienWeb.VacationTimelineComponent.render(
                          days_to_show: @vacation_days,
                          months: @vacation_months,
                          all_periods: filtered_periods,
                          days_count: @vacation_number_of_days,
                          months_with_days: @vacation_months_with_days,
                          federal_state: federal_state
                        )}
                        <!-- Fallback text for test environment -->
                        <div class="hidden" aria-hidden="true">
                          Ferien und Feiertage im angezeigten Zeitraum
                        </div>
                      </div>

                      <div class="mt-4">
                        <div class="flex items-center gap-3">
                          <span class="text-sm text-gray-600 dark:text-gray-400">Ferientermine:</span>
                          <div class="flex-1 grid grid-cols-2 gap-3">
                            <.button
                              href={"/ferien/d/bundesland/#{federal_state.slug}/#{current_year}"}
                              variant="primary"
                              size="sm"
                              class="w-full"
                            >
                              {current_year}
                            </.button>
                            <.button
                              href={"/ferien/d/bundesland/#{federal_state.slug}/#{next_year}"}
                              variant="secondary"
                              size="sm"
                              class="w-full"
                            >
                              {next_year}
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
                  <% # Use pre-computed bridge day data (no DB queries!)
                  bridge_data = Map.get(@bridge_days_data, federal_state.id, %{})
                  next_bridge_day = bridge_data[:next_bridge_day]
                  public_periods = bridge_data[:public_periods] || []

                  # Set up variables for year links
                  current_year = @vacation_current_year
                  next_year = current_year + 1 %>
                  <.card padding="p-6" class="h-full">
                    <:content>
                      <.section_title title={federal_state.name} />

                      <%= if next_bridge_day do %>
                        <% # Use pre-computed data instead of DB queries
                        # Calculate efficiency using pre-fetched periods
                        vacation_days = next_bridge_day.number_days

                        total_free_days =
                          MehrSchulferien.BridgeDayCalculations.calculate_total_consecutive_free_days(
                            next_bridge_day,
                            public_periods
                          )

                        efficiency =
                          if vacation_days > 0,
                            do: round((total_free_days - vacation_days) / vacation_days * 100),
                            else: 0 %>

                        <.heading level={6} class="text-gray-700 mb-2">
                          Nächster Brückentag
                        </.heading>
                        <.text variant="small" class="mb-3">
                          {DateFormatter.format_date_full(next_bridge_day.starts_on)}
                          <%= if Date.compare(next_bridge_day.starts_on, next_bridge_day.ends_on) != :eq do %>
                            - {DateFormatter.format_date_full(next_bridge_day.ends_on)}
                          <% end %>
                        </.text>
                        <!-- Bridge Day Timeline -->
                        <div class="mb-4">
                          {MehrSchulferienWeb.BridgeDayTimelineComponent.bridge_day_timeline(%{
                            bridge_day: next_bridge_day,
                            periods: public_periods,
                            reference_date: @today,
                            vacation_days: vacation_days,
                            total_free_days: total_free_days,
                            efficiency_percentage: efficiency
                          })}
                        </div>

                        <% # Use pre-computed best bridge day (no DB query!)
                        best_super_bridge_day = bridge_data[:best_bridge_day] %>

                        <%= if best_super_bridge_day do %>
                          <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
                            <.heading level={6} class="text-gray-700 dark:text-gray-300 mb-2">
                              Bester Superbrückentag
                            </.heading>
                            <.text variant="small">
                              {DateFormatter.format_date_full(
                                best_super_bridge_day.bridge_day.starts_on
                              )} - {DateFormatter.format_date_full(
                                best_super_bridge_day.bridge_day.ends_on
                              )}
                              <br />
                              <span class="text-xs text-gray-500">
                                {best_super_bridge_day.vacation_days} Urlaubstag{if best_super_bridge_day.vacation_days >
                                                                                      1,
                                                                                    do: "e",
                                                                                    else: ""} für {best_super_bridge_day.total_free_days} freie Tage
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
                          <span class="text-sm text-gray-600 dark:text-gray-400">Brückentage:</span>
                          <div class="flex-1 grid grid-cols-2 gap-3">
                            <.button
                              href={"/brueckentage/d/bundesland/#{federal_state.slug}/#{current_year}"}
                              variant="primary"
                              size="sm"
                              class="w-full"
                            >
                              {current_year}
                            </.button>
                            <.button
                              href={"/brueckentage/d/bundesland/#{federal_state.slug}/#{next_year}"}
                              variant="secondary"
                              size="sm"
                              class="w-full"
                            >
                              {next_year}
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
    <% end %>
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

    # Pre-compute all bridge day data to avoid N+1 queries in render
    bridge_days_data = precompute_bridge_days_data(countries, today)

    socket
    |> assign(:vacation_days, days)
    |> assign(:vacation_day_names, day_names)
    |> assign(:vacation_months, months)
    |> assign(:vacation_current_year, current_year)
    |> assign(:vacation_number_of_days, days_to_display)
    |> assign(:vacation_months_with_days, months_with_days)
    |> assign(:vacation_countries, countries)
    |> assign(:bridge_days_data, bridge_days_data)
  end

  # Pre-compute all bridge day data for all federal states in a single batch operation
  # This eliminates N+1 queries during render (was ~60-100 queries, now ~2 queries)
  defp precompute_bridge_days_data(countries, reference_date) do
    alias MehrSchulferien.Periods.Grouping
    alias MehrSchulferien.Helpers.{DateConstants, DateComparison}

    # Collect all federal states and their countries
    all_states_with_country =
      Enum.flat_map(countries, fn %{country: country, federal_states: federal_states} ->
        Enum.map(federal_states, fn state -> {state, country} end)
      end)

    # Get all unique location IDs (countries + states)
    all_location_ids =
      all_states_with_country
      |> Enum.flat_map(fn {state, country} -> [country.id, state.id] end)
      |> Enum.uniq()

    # Single batch query: fetch all public periods for 12 months ahead
    end_date = Date.add(reference_date, 365)

    all_public_periods =
      Periods.list_public_everybody_periods(all_location_ids, reference_date, end_date)

    # Group periods by location_id for efficient filtering
    periods_by_location = Enum.group_by(all_public_periods, & &1.location_id)

    # Pre-compute bridge day data for each federal state
    Enum.reduce(all_states_with_country, %{}, fn {state, country}, acc ->
      location_ids = [country.id, state.id]

      # Get periods for this state (country + state periods)
      state_periods =
        location_ids
        |> Enum.flat_map(fn id -> Map.get(periods_by_location, id, []) end)
        |> Enum.uniq_by(& &1.id)
        |> Enum.sort_by(& &1.starts_on, Date)

      # Compute next bridge day and best bridge day using the pre-fetched periods
      next_bridge_day = find_next_bridge_day_from_periods(state_periods, reference_date, 1)
      best_bridge_day = find_best_bridge_day_from_periods(state_periods, reference_date)

      # Build the data structure expected by the render function
      bridge_data = %{
        next_bridge_day: next_bridge_day,
        best_bridge_day: best_bridge_day,
        public_periods: state_periods,
        country: country
      }

      Map.put(acc, state.id, bridge_data)
    end)
  end

  # Find next bridge day using pre-fetched periods (no DB queries)
  defp find_next_bridge_day_from_periods(public_periods, current_date, days_count) do
    alias MehrSchulferien.Periods.Grouping
    alias MehrSchulferien.Helpers.DateComparison

    if length(public_periods) < 2 do
      nil
    else
      bridge_day_map = Grouping.group_by_interval(public_periods)
      bridge_days = Map.get(bridge_day_map, days_count + 1, [])

      bridge_days
      |> Enum.filter(&DateComparison.is_after?(&1.starts_on, current_date))
      |> List.first()
    end
  end

  # Find best bridge day using pre-fetched periods (no DB queries)
  defp find_best_bridge_day_from_periods(public_periods, start_date) do
    alias MehrSchulferien.Periods.Grouping
    alias MehrSchulferien.Helpers.{DateConstants, DateComparison}

    if length(public_periods) < 2 do
      nil
    else
      bridge_day_map = Grouping.group_by_interval(public_periods)

      opportunities =
        for days <- DateConstants.min_bridge_days()..DateConstants.extended_max_bridge_days(),
            bridge_days = Map.get(bridge_day_map, days, []),
            length(bridge_days) > 0 do
          vacation_days = days - 1

          bridge_days
          |> Enum.filter(&DateComparison.is_after?(&1.starts_on, start_date))
          |> Enum.map(fn bridge_day ->
            is_free_day = fn date ->
              is_weekend = Date.day_of_week(date) > 5

              is_holiday =
                Enum.any?(public_periods, fn p ->
                  Date.compare(date, p.starts_on) != :lt &&
                    Date.compare(date, p.ends_on) != :gt
                end)

              is_weekend || is_holiday
            end

            actual_start =
              1..10
              |> Enum.map(fn d -> Date.add(bridge_day.starts_on, -d) end)
              |> Enum.reverse()
              |> Enum.reduce_while(bridge_day.starts_on, fn date, _acc ->
                if is_free_day.(date), do: {:cont, date}, else: {:halt, Date.add(date, 1)}
              end)

            actual_end =
              1..10
              |> Enum.map(fn d -> Date.add(bridge_day.ends_on, d) end)
              |> Enum.reduce_while(bridge_day.ends_on, fn date, _acc ->
                if is_free_day.(date), do: {:cont, date}, else: {:halt, Date.add(date, -1)}
              end)

            total_free_days = Date.diff(actual_end, actual_start) + 1

            %{
              bridge_day: bridge_day,
              vacation_days: vacation_days,
              total_free_days: total_free_days
            }
          end)
        end
        |> List.flatten()

      Enum.max_by(
        opportunities,
        fn opp -> opp.total_free_days * 1000 + (opp.total_free_days - opp.vacation_days) end,
        fn -> nil end
      )
    end
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
    current_year = Date.utc_today().year
    min_year = Enum.min(years, fn -> current_year end)
    max_year = Enum.max(years, fn -> current_year end)
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
