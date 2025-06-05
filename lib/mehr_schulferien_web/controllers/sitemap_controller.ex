defmodule MehrSchulferienWeb.SitemapController do
  use MehrSchulferienWeb, :controller

  plug :put_layout, false

  alias MehrSchulferien.{Calendars, Locations}
  alias MehrSchulferien.Repo
  import Ecto.Query

  def sitemap(conn, _params) do
    today = Calendars.DateHelpers.today_berlin()
    countries_with_locations = fetch_all_locations_with_periods()

    conn
    |> put_resp_content_type("text/xml")
    |> render("sitemap.xml", countries: countries_with_locations, today: today)
  end

  defp fetch_all_locations_with_periods do
    alias MehrSchulferien.Locations.Location
    alias MehrSchulferien.Periods.Period

    # Get all countries
    countries = Locations.list_countries()

    # Get all relevant location IDs in a single query
    countries
    |> Enum.map(fn country ->
      # For development environment, limit the number of entries
      limit_count = if Application.get_env(:mehr_schulferien, :env) == :dev, do: 20, else: 10000

      # Get federal states
      federal_states_query =
        from l in Location,
          where: l.parent_location_id == ^country.id and l.is_federal_state == true,
          limit: ^limit_count

      federal_states = Repo.all(federal_states_query)
      federal_state_ids = Enum.map(federal_states, & &1.id)

      # Get counties for all federal states in one query
      counties_query =
        from l in Location,
          where: l.parent_location_id in ^federal_state_ids and l.is_county == true,
          limit: ^limit_count

      counties = Repo.all(counties_query)
      county_ids = Enum.map(counties, & &1.id)

      # Get cities with schools in one query
      cities_with_schools_query =
        from city in Location,
          where: city.parent_location_id in ^county_ids and city.is_city == true,
          join: school in Location,
          on: school.parent_location_id == city.id and school.is_school == true,
          distinct: city.id,
          select: city,
          limit: ^limit_count

      cities = Repo.all(cities_with_schools_query)
      city_ids = Enum.map(cities, & &1.id)

      # Get schools in one query
      schools_query =
        from l in Location,
          where: l.parent_location_id in ^city_ids and l.is_school == true,
          limit: ^limit_count

      schools = Repo.all(schools_query)

      # Collect all location IDs
      all_location_ids =
        [country.id] ++ federal_state_ids ++ city_ids ++ Enum.map(schools, & &1.id) ++ county_ids

      # Fetch all periods for these locations in a single query
      periods_query =
        from p in Period,
          where: p.location_id in ^all_location_ids,
          preload: [:holiday_or_vacation_type]

      all_periods = Repo.all(periods_query)

      # Group periods by location ID
      periods_by_location_id = Enum.group_by(all_periods, & &1.location_id)

      # Get vacation types for country
      is_school_vacation_types = Calendars.list_is_school_vacation_types(country)

      is_school_vacation_types =
        if Application.get_env(:mehr_schulferien, :env) == :dev,
          do: Enum.take(is_school_vacation_types, 20),
          else: is_school_vacation_types

      # Add periods and metadata to each location
      federal_states_with_meta = add_periods_to_locations(federal_states, periods_by_location_id)
      counties_with_meta = add_periods_to_locations(counties, periods_by_location_id)
      cities_with_meta = add_periods_to_locations(cities, periods_by_location_id)
      schools_with_meta = add_periods_to_locations(schools, periods_by_location_id)

      # Map of federal_state_id -> federal_state for easier lookup
      federal_states_by_id =
        Enum.reduce(federal_states_with_meta, %{}, fn state, acc ->
          Map.put(acc, state.id, state)
        end)

      # Map of county_id -> county for easier lookup
      counties_by_id =
        Enum.reduce(counties_with_meta, %{}, fn county, acc ->
          Map.put(acc, county.id, county)
        end)

      # Add federal_state and county periods to each city
      cities_with_meta =
        Enum.map(cities_with_meta, fn city ->
          # Get the county and federal state for this city
          county = Map.get(counties_by_id, city.parent_location_id)

          if county do
            federal_state = Map.get(federal_states_by_id, county.parent_location_id)

            # Get all periods
            city_periods = Map.get(city, :periods, [])
            county_periods = Map.get(county, :periods, [])

            federal_state_periods =
              if federal_state, do: Map.get(federal_state, :periods, []), else: []

            country_periods = Map.get(periods_by_location_id, country.id, [])

            # Combine all periods
            combined_periods =
              city_periods ++ county_periods ++ federal_state_periods ++ country_periods

            # Recalculate metadata with combined periods
            period_years =
              combined_periods
              |> Enum.flat_map(fn period ->
                start_year = period.starts_on.year
                end_year = period.ends_on.year
                start_year..end_year
              end)
              |> Enum.uniq()
              |> Enum.sort()

            # Update the city with combined periods
            %{city | periods: combined_periods, period_years: period_years}
          else
            city
          end
        end)

      # For schools, also add the city periods
      schools_with_meta =
        Enum.map(schools_with_meta, fn school ->
          city = Enum.find(cities_with_meta, fn city -> city.id == school.parent_location_id end)

          if city do
            city_periods = Map.get(city, :periods, [])
            school_periods = Map.get(school, :periods, [])
            combined_periods = school_periods ++ city_periods

            # Recalculate metadata with combined periods
            period_years =
              combined_periods
              |> Enum.flat_map(fn period ->
                start_year = period.starts_on.year
                end_year = period.ends_on.year
                start_year..end_year
              end)
              |> Enum.uniq()
              |> Enum.sort()

            %{school | periods: combined_periods, period_years: period_years}
          else
            school
          end
        end)

      # Add metadata to country
      country_with_meta =
        country
        |> Map.put(:periods, Map.get(periods_by_location_id, country.id, []))
        |> add_last_modified_metadata()

      %{
        country: country_with_meta,
        federal_states: federal_states_with_meta,
        cities: cities_with_meta,
        is_school_vacation_types: is_school_vacation_types,
        schools: schools_with_meta
      }
    end)
  end

  defp add_periods_to_locations(locations, periods_by_location_id) do
    Enum.map(locations, fn location ->
      location
      |> Map.put(:periods, Map.get(periods_by_location_id, location.id, []))
      |> add_last_modified_metadata()
    end)
  end

  # Add metadata to a location including last_modified date and period years
  defp add_last_modified_metadata(location) do
    periods = Map.get(location, :periods, [])

    # Find the most recent update timestamp from periods
    last_period_update =
      case periods do
        [] ->
          nil

        periods ->
          periods
          |> Enum.map(& &1.updated_at)
          |> Enum.max_by(
            fn
              # Convert NaiveDateTime to comparable integer
              %NaiveDateTime{} = dt ->
                NaiveDateTime.to_erl(dt) |> :calendar.datetime_to_gregorian_seconds()

              dt ->
                dt |> DateTime.to_unix()
            end,
            fn -> nil end
          )
      end

    # Extract unique years from periods
    period_years =
      case periods do
        [] ->
          []

        periods ->
          periods
          |> Enum.flat_map(fn period ->
            # Generate list of years that this period spans
            start_year = period.starts_on.year
            end_year = period.ends_on.year
            start_year..end_year
          end)
          |> Enum.uniq()
          |> Enum.sort()
      end

    # Determine last modified date from period update
    last_modified =
      if last_period_update do
        # Handle both NaiveDateTime and DateTime
        case last_period_update do
          %NaiveDateTime{} -> NaiveDateTime.to_date(last_period_update)
          %DateTime{} -> DateTime.to_date(last_period_update)
          # Fallback in case of unexpected type
          _ -> nil
        end
      else
        nil
      end

    location
    |> Map.put(:last_modified, last_modified)
    |> Map.put(:period_years, period_years)
  end
end
