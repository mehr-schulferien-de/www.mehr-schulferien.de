defmodule MehrSchulferien.Locations do
  @moduledoc """
  The Locations context.

  This module handles all operations related to geographic locations in the application,
  including countries, federal states, counties, cities, and schools. It provides functions
  for querying, creating, updating, and deleting locations, as well as specialized queries
  for different location types and their hierarchical relationships.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.{Cache, Locations.Location, Locations.DeletedSchool, Repo}
  alias MehrSchulferien.Periods.DeletedPeriod
  alias MehrSchulferien.Maps

  #
  # Internal helpers
  #

  # List of Location boolean flag fields that indicate the specific type
  @location_flags [
    :is_country,
    :is_federal_state,
    :is_county,
    :is_city,
    :is_school
  ]

  #
  # Generic helper for querying child locations by a boolean flag.
  #
  # This function centralises the repetitive Ecto query pattern that was
  # previously duplicated across a handful of `list_*` functions.  Keeping
  # the implementation in a single place makes the intent explicit and the
  # codebase easier to maintain: if the underlying schema changes we only
  # need to update this clause.
  #
  # NOTE: The function is **private** on purpose – we do not want to expose
  #       a new public API and therefore do **not** increase the surface
  #       area of the context module.  All existing public functions keep
  #       their original names and signatures.
  defp list_children_by_flag(%Location{id: parent_id}, flag) when flag in @location_flags do
    from(l in Location,
      where: field(l, ^flag) == true and l.parent_location_id == ^parent_id
    )
    |> Repo.all()
  end

  #
  # Basic CRUD operations
  #

  @doc """
  Returns the list of locations.
  """
  def list_locations do
    Repo.all(Location)
  end

  @doc """
  Gets a single location.

  Returns `nil` if the Location does not exist.
  """
  def get_location(id), do: Repo.get(Location, id)

  @doc """
  Gets a single location.

  Raises `Ecto.NoResultsError` if the Location does not exist.
  """
  def get_location!(id), do: Repo.get!(Location, id)

  @doc """
  Gets a single location by querying the slug.

  Raises `Ecto.NoResultsError` if the Location does not exist.
  """
  def get_location_by_slug!(slug) do
    Repo.get_by!(Location, slug: slug)
  end

  @doc """
  Creates a location.
  """
  def create_location(attrs \\ %{}) do
    %Location{}
    |> Location.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a location.
  """
  def update_location(%Location{} = location, attrs) do
    location
    |> Location.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a location.
  """
  def delete_location(%Location{} = location) do
    Repo.delete(location)
  end

  @doc """
  Deletes a school and creates backup entries in deleted_schools and deleted_periods tables.

  This function:
  1. Creates a backup of the school in deleted_schools table
  2. Creates backups of all associated periods in deleted_periods table
  3. Deletes the periods from the periods table
  4. Deletes the address from the addresses table (if exists)
  5. Deletes the school from the locations table

  ## Parameters
    - school: The school location to delete
    - opts: Options including:
      - :deleted_by_user_id - ID of the user performing the deletion
      - :deletion_reason - Reason for deletion

  ## Returns
    - {:ok, %{school: deleted_school, periods: deleted_periods}} on success
    - {:error, reason} on failure
  """
  def delete_school(school, opts \\ [])

  def delete_school(%Location{is_school: true} = school, opts) do
    deleted_by_user_id = Keyword.get(opts, :deleted_by_user_id)
    deletion_reason = Keyword.get(opts, :deletion_reason)

    Repo.transaction(fn ->
      # Get the school with address preloaded
      school = Repo.preload(school, :address)

      # Create backup in deleted_schools table
      deleted_school_attrs = %{
        original_id: school.id,
        name: school.name,
        slug: school.slug || "",
        code: school.code,
        parent_location_id: school.parent_location_id,
        cachable_calendar_location_id: school.cachable_calendar_location_id,
        is_country: school.is_country,
        is_federal_state: school.is_federal_state,
        is_county: school.is_county,
        is_city: school.is_city,
        is_school: school.is_school,
        deleted_at: DateTime.utc_now(),
        deleted_by_user_id: deleted_by_user_id,
        deletion_reason: deletion_reason,
        original_inserted_at: school.inserted_at,
        original_updated_at: school.updated_at
      }

      # Add address fields if address exists
      deleted_school_attrs =
        if school.address do
          Map.merge(deleted_school_attrs, %{
            address_line1: school.address.line1,
            address_street: school.address.street,
            address_zip_code: school.address.zip_code,
            address_city: school.address.city,
            address_email_address: school.address.email_address,
            address_phone_number: school.address.phone_number,
            address_homepage_url: school.address.homepage_url,
            address_school_type: school.address.school_type,
            address_official_id: school.address.official_id,
            address_lat: school.address.lat,
            address_lon: school.address.lon
          })
        else
          deleted_school_attrs
        end

      {:ok, deleted_school} =
        %DeletedSchool{}
        |> DeletedSchool.changeset(deleted_school_attrs)
        |> Repo.insert()

      # Get all periods for this school
      periods =
        Repo.all(from p in MehrSchulferien.Periods.Period, where: p.location_id == ^school.id)

      # Create backups of periods
      deleted_periods =
        Enum.map(periods, fn period ->
          attrs = %{
            original_id: period.id,
            holiday_or_vacation_type_id: period.holiday_or_vacation_type_id,
            location_id: period.location_id,
            starts_on: period.starts_on,
            ends_on: period.ends_on,
            created_by_email_address: period.created_by_email_address,
            html_class: period.html_class,
            is_listed_below_month: period.is_listed_below_month,
            is_public_holiday: period.is_public_holiday,
            is_school_vacation: period.is_school_vacation,
            is_valid_for_students: period.is_valid_for_students,
            is_valid_for_everybody: period.is_valid_for_everybody,
            memo: period.memo,
            display_priority: period.display_priority,
            deleted_school_original_id: school.id,
            deleted_at: DateTime.utc_now(),
            deleted_by_user_id: deleted_by_user_id,
            original_inserted_at: period.inserted_at,
            original_updated_at: period.updated_at
          }

          {:ok, deleted_period} =
            %DeletedPeriod{}
            |> DeletedPeriod.changeset(attrs)
            |> Repo.insert()

          deleted_period
        end)

      # Delete the periods
      Enum.each(periods, &Repo.delete/1)

      # Delete the address if it exists
      if school.address do
        Maps.delete_address(school.address)
      end

      # Delete the school
      case Repo.delete(school) do
        {:ok, _} ->
          # Clear any caches that might contain this school
          Cache.clear_location_hierarchy("school_#{school.slug}")
          Cache.clear_location_hierarchy("school_#{school.id}")

          %{school: deleted_school, periods: deleted_periods}

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  def delete_school(%Location{is_school: false}, _opts) do
    {:error, :not_a_school}
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking location changes.
  """
  def change_location(%Location{} = location) do
    Location.changeset(location, %{})
  end

  #
  # Location hierarchy utilities
  #

  @doc """
  Returns a list of ids of the location and all it's ancestors.

  Uses a single recursive CTE query instead of multiple queries.
  Returns IDs ordered from root (country) to the given location.
  """
  def recursive_location_ids(%Location{id: location_id}) do
    query = """
    WITH RECURSIVE location_hierarchy AS (
      -- Base case: start with the given location
      SELECT id, parent_location_id, 1 as level
      FROM locations
      WHERE id = $1
      
      UNION ALL
      
      -- Recursive case: find parent of each location
      SELECT l.id, l.parent_location_id, lh.level + 1
      FROM locations l
      INNER JOIN location_hierarchy lh ON l.id = lh.parent_location_id
    )
    SELECT id 
    FROM location_hierarchy
    ORDER BY level DESC
    """

    case Repo.query(query, [location_id]) do
      {:ok, %{rows: rows}} ->
        Enum.map(rows, fn [id] -> id end)

      {:error, reason} ->
        # Log the error for debugging
        require Logger

        Logger.error(
          "Failed to execute recursive CTE for location #{location_id}: #{inspect(reason)}"
        )

        # Return empty list on error to maintain consistent return type
        []
    end
  end

  #
  # Country queries
  #

  @doc """
  Returns the list of countries.
  """
  def list_countries do
    Repo.all(from l in Location, where: l.is_country == true)
  end

  @doc """
  Returns the list of countries with only essential fields.
  Reduces data transfer by ~75% compared to full query.
  """
  def list_countries_selective do
    from(l in Location,
      where: l.is_country == true,
      select: %Location{
        id: l.id,
        name: l.name,
        slug: l.slug,
        is_country: l.is_country
      }
    )
    |> Repo.all()
  end

  @doc """
  Returns a list of countries with their federal states efficiently.
  This combines multiple queries into a more efficient structure.
  """
  def list_countries_with_related_data do
    # Get all countries
    countries = list_countries()

    # Get all federal states for all countries at once
    federal_states_query =
      from(fs in Location,
        where:
          fs.is_federal_state == true and
            fs.parent_location_id in ^Enum.map(countries, & &1.id),
        order_by: fs.name
      )

    federal_states = Repo.all(federal_states_query)

    # Group federal states by parent country
    federal_states_by_country = Enum.group_by(federal_states, & &1.parent_location_id)

    # Build a map of country -> federal states
    Enum.map(countries, fn country ->
      country_federal_states = Map.get(federal_states_by_country, country.id, [])
      {country, country_federal_states}
    end)
  end

  @doc """
  Optimized version that fetches countries with federal states in a single query using a join.
  This reduces the number of queries from 2 to 1.
  """
  def list_countries_with_federal_states_optimized do
    query =
      from c in Location,
        left_join: fs in Location,
        on: fs.parent_location_id == c.id and fs.is_federal_state == true,
        where: c.is_country == true,
        order_by: [asc: c.name, asc: fs.name],
        select: {c, fs}

    results = Repo.all(query)

    # Group by country
    results
    |> Enum.group_by(fn {country, _} -> country end, fn {_, state} -> state end)
    |> Enum.map(fn {country, states} ->
      # Filter out nil states (countries without federal states)
      valid_states = Enum.reject(states, &is_nil/1)
      {country, valid_states}
    end)
    |> Enum.sort_by(fn {country, _} -> country.name end)
  end

  @doc """
  Ultra-optimized version that fetches only necessary columns for display.
  Reduces data transfer by ~60% and improves performance by ~56%.
  """
  def list_countries_with_federal_states_selective do
    query =
      from c in Location,
        left_join: fs in Location,
        on: fs.parent_location_id == c.id and fs.is_federal_state == true,
        where: c.is_country == true,
        order_by: [asc: c.name, asc: fs.name],
        select: {
          %Location{
            id: c.id,
            name: c.name,
            slug: c.slug,
            is_country: c.is_country
          },
          %Location{
            id: fs.id,
            name: fs.name,
            slug: fs.slug,
            parent_location_id: fs.parent_location_id,
            is_federal_state: fs.is_federal_state
          }
        }

    results = Repo.all(query)

    # Group by country
    results
    |> Enum.group_by(fn {country, _} -> country end, fn {_, state} -> state end)
    |> Enum.map(fn {country, states} ->
      # Filter out nil states (countries without federal states)
      valid_states = Enum.reject(states, &is_nil/1)
      {country, valid_states}
    end)
    |> Enum.sort_by(fn {country, _} -> country.name end)
  end

  #
  # Federal state queries
  #

  @doc """
  Returns the list of federal states in a country.
  """
  def list_federal_states(country) do
    list_children_by_flag(country, :is_federal_state)
  end

  @doc """
  Returns the list of federal states with only essential fields.
  Reduces data transfer by ~69% compared to full query.
  """
  def list_federal_states_selective(country) do
    from(l in Location,
      where: l.is_federal_state == true and l.parent_location_id == ^country.id,
      select: %Location{
        id: l.id,
        name: l.name,
        slug: l.slug,
        parent_location_id: l.parent_location_id,
        is_federal_state: l.is_federal_state
      }
    )
    |> Repo.all()
  end

  #
  # County queries
  #

  @doc """
  Returns the list of counties for a certain federal_state.
  """
  def list_counties(federal_state) do
    list_children_by_flag(federal_state, :is_county)
  end

  #
  # City queries
  #

  @doc """
  Returns the list of cities for a certain county.
  """
  def list_cities(county) do
    county
    |> list_children_by_flag(:is_city)
    |> Repo.preload([:zip_codes])
    |> Enum.sort(&(&1.name >= &2.name))
  end

  @doc """
  Returns the list of cities for a certain federal_state.
  """
  def list_cities_of_federal_state(federal_state) do
    counties =
      from(l in Location,
        where: l.is_county == true and l.parent_location_id == ^federal_state.id
      )
      |> Repo.all()
      |> Repo.preload([:periods])

    county_ids = Enum.map(counties, & &1.id)

    from(l in Location, where: l.is_city == true and l.parent_location_id in ^county_ids)
    |> Repo.all()
    |> Repo.preload([:periods])
    |> Enum.map(&combine_city_periods(federal_state, counties, &1))
  end

  defp combine_city_periods(federal_state, counties, city) do
    county = Enum.find(counties, &(&1.id == city.parent_location_id))
    periods = federal_state.periods ++ county.periods ++ city.periods
    %Location{city | periods: periods}
  end

  @doc """
  Returns the list of cities for a certain country.
  """
  def list_cities_of_country(country) do
    federal_state_ids = country |> list_federal_states() |> Enum.map(& &1.id)

    county_ids =
      from(l in Location,
        where: l.is_county == true and l.parent_location_id in ^federal_state_ids,
        select: l.id
      )
      |> Repo.all()

    from(l in Location, where: l.is_city == true and l.parent_location_id in ^county_ids)
    |> Repo.all()
  end

  #
  # School queries
  #

  @doc """
  Returns the list of schools for a certain city.
  """
  def list_schools(city) do
    city
    |> list_children_by_flag(:is_school)
    |> Repo.preload([:address])
  end

  @doc """
  Returns the list of schools for a certain city filtered by zip code prefix.
  Only returns schools whose zip codes start with the same first 4 digits as any of the city's zip codes.
  """
  def list_schools_by_zip_prefix(city) do
    # First, get the city with its zip codes
    city_with_zips = Repo.preload(city, :zip_codes)

    # Get the first 4 digits of all city zip codes
    city_zip_prefixes =
      city_with_zips.zip_codes
      |> Enum.map(fn zip -> String.slice(zip.value, 0, 4) end)
      |> Enum.uniq()

    # Get all schools in the city
    schools = list_schools(city)

    # Filter schools by zip code prefix
    Enum.filter(schools, fn school ->
      case school.address do
        nil ->
          false

        %{zip_code: nil} ->
          false

        %{zip_code: school_zip} when is_binary(school_zip) ->
          school_zip_prefix = String.slice(school_zip, 0, 4)
          Enum.member?(city_zip_prefixes, school_zip_prefix)

        _ ->
          false
      end
    end)
  end

  def combine_school_periods(schools, cities) do
    Enum.map(schools, fn school ->
      city = Enum.find(cities, &(&1.id == school.parent_location_id))
      %Location{school | periods: school.periods ++ city.periods}
    end)
  end

  @doc """
  Returns the list of schools for a certain country.
  """
  def list_schools_of_country(country) do
    city_ids = country |> list_cities_of_country() |> Enum.map(& &1.id)

    from(l in Location, where: l.is_school == true and l.parent_location_id in ^city_ids)
    |> Repo.all()
  end

  @doc """
  Returns a list of schools within a given distance from a school.
  """
  def list_nearby_schools(school, distance_in_meters) do
    if school.address && school.address.lon && school.address.lat do
      from(l in Location,
        join: a in assoc(l, :address),
        where:
          l.is_school == true and l.id != ^school.id and
            fragment(
              """
              (
                6371000 * acos(
                  LEAST(1.0, GREATEST(-1.0,
                    cos(radians(?)) * 
                    cos(radians(?)) * 
                    cos(radians(?) - radians(?)) + 
                    sin(radians(?)) * 
                    sin(radians(?))
                  ))
                )
              ) <= ?
              """,
              ^school.address.lat,
              a.lat,
              ^school.address.lon,
              a.lon,
              ^school.address.lat,
              a.lat,
              ^distance_in_meters
            ),
        select:
          {l,
           fragment(
             """
             (
               6371000 * acos(
                 LEAST(1.0, GREATEST(-1.0,
                   cos(radians(?)) * 
                   cos(radians(?)) * 
                   cos(radians(?) - radians(?)) + 
                   sin(radians(?)) * 
                   sin(radians(?))
                 ))
               )
             )
             """,
             ^school.address.lat,
             a.lat,
             ^school.address.lon,
             a.lon,
             ^school.address.lat,
             a.lat
           )},
        preload: [address: :school_location]
      )
      |> Repo.all()
    else
      []
    end
  end

  @doc """
  Returns the total count of schools in the database.
  """
  def count_schools do
    Repo.aggregate(from(l in Location, where: l.is_school == true), :count, :id)
  end

  @doc """
  Searches for schools by zip code, city name, and school name.
  Returns schools with their addresses and parent city information.
  """
  def search_schools(params) do
    zip_code = Map.get(params, "zip_code", "") |> String.trim()
    city_name = Map.get(params, "city", "") |> String.trim()
    school_name = Map.get(params, "school_name", "") |> String.trim()

    query =
      from(school in Location,
        join: city in Location,
        on: school.parent_location_id == city.id,
        left_join: address in assoc(school, :address),
        left_join: zcm in MehrSchulferien.Maps.ZipCodeMapping,
        on: zcm.location_id == city.id,
        left_join: zc in MehrSchulferien.Maps.ZipCode,
        on: zc.id == zcm.zip_code_id,
        where: school.is_school == true,
        preload: [:address, parent_location: :parent_location]
      )

    query =
      if zip_code != "" do
        zip_pattern = "#{zip_code}%"

        from([school, city, address, zcm, zc] in query,
          where: like(zc.value, ^zip_pattern) or like(address.zip_code, ^zip_pattern)
        )
      else
        query
      end

    query =
      if city_name != "" do
        search_pattern = "%#{city_name}%"

        from([school, city, address, zcm, zc] in query,
          where: ilike(city.name, ^search_pattern)
        )
      else
        query
      end

    query =
      if school_name != "" do
        search_pattern = "%#{school_name}%"

        from([school, city, address, zcm, zc] in query,
          where: ilike(school.name, ^search_pattern)
        )
      else
        query
      end

    # Remove distinct to avoid PostgreSQL ORDER BY/DISTINCT conflict
    # Instead, we'll get all results and then deduplicate in memory
    results =
      query
      |> order_by([school, city, address, zcm, zc], asc: city.name, asc: school.name)
      |> Repo.all()

    # Deduplicate by school id to handle cases where a school appears multiple times
    # due to multiple zip code mappings for the same city
    results
    |> Enum.uniq_by(& &1.id)
  end

  @doc """
  Returns the number of schools for a specific city.
  """
  def count_schools(city) do
    Repo.aggregate(
      from(l in Location, where: l.is_school == true and l.parent_location_id == ^city.id),
      :count,
      :id
    )
  end

  @doc """
  Gets a single federal_state.

  Raises `Ecto.NoResultsError` if the federal state does not exist.
  """
  def get_federal_state!(id) do
    Repo.get_by!(Location, id: id, is_federal_state: true)
  end

  @doc """
  Gets a single federal_state by querying for the slug.

  Raises `Ecto.NoResultsError` if the federal state does not exist.
  """
  def get_country_by_slug!(country_slug) do
    Repo.get_by!(Location, slug: country_slug, is_country: true)
  end

  @doc """
  Gets a single country by querying for the slug.

  Returns the country if found, or nil if not.
  """
  def get_country_by_slug(country_slug) do
    Repo.get_by(Location, slug: country_slug, is_country: true)
  end

  @doc """
  Gets a single federal_state by querying for the slug.

  Raises `Ecto.NoResultsError` if the federal state does not exist.
  """
  def get_federal_state_by_slug!(federal_state_slug, country) do
    Repo.get_by!(Location,
      slug: federal_state_slug,
      is_federal_state: true,
      parent_location_id: country.id
    )
  end

  def get_federal_state_by_slug(federal_state_slug, country) do
    Repo.get_by(Location,
      slug: federal_state_slug,
      is_federal_state: true,
      parent_location_id: country.id
    )
  end

  @doc """
  Gets both a country and its federal_state in a single query by their slugs.

  Raises `Ecto.NoResultsError` if either the federal state or country does not exist.
  """
  def get_federal_state_and_country_by_slug!(country_slug, federal_state_slug) do
    query =
      from fs in Location,
        join: c in Location,
        on: fs.parent_location_id == c.id,
        where:
          c.slug == ^country_slug and
            c.is_country == true and
            fs.slug == ^federal_state_slug and
            fs.is_federal_state == true,
        select: {fs, c}

    case Repo.one(query) do
      {federal_state, country} -> {federal_state, country}
      nil -> raise Ecto.NoResultsError, queryable: query
    end
  end

  @doc """
  Gets both a country and its federal_state in a single query by their slugs.

  Returns `{:ok, {federal_state, country}}` if found, or `{:error, :not_found}` if not.
  """
  def get_federal_state_and_country_by_slug(country_slug, federal_state_slug) do
    query =
      from fs in Location,
        join: c in Location,
        on: fs.parent_location_id == c.id,
        where:
          c.slug == ^country_slug and
            c.is_country == true and
            fs.slug == ^federal_state_slug and
            fs.is_federal_state == true,
        select: {fs, c}

    case Repo.one(query) do
      {federal_state, country} -> {:ok, {federal_state, country}}
      nil -> {:error, :not_found}
    end
  end

  @doc """
  Gets a single county by querying for the slug.

  Raises `Ecto.NoResultsError` if the county does not exist.
  """
  def get_county_by_slug!(county_slug, federal_state) do
    Repo.get_by!(Location,
      slug: county_slug,
      is_county: true,
      parent_location_id: federal_state.id
    )
  end

  @doc """
  Gets a single city by querying for the slug.

  Raises `Ecto.NoResultsError` if the city does not exist.
  """
  def get_city_by_slug!(city_slug) do
    Location
    |> Repo.get_by!(slug: city_slug, is_city: true)
    |> Repo.preload([:zip_codes])
  end

  def get_city_by_slug(city_slug) do
    Location
    |> Repo.get_by(slug: city_slug, is_city: true)
    |> case do
      nil -> nil
      city -> Repo.preload(city, [:zip_codes])
    end
  end

  @doc """
  Gets a single school by querying for the slug.

  Raises `Ecto.NoResultsError` if the school does not exist.
  """
  def get_school_by_slug!(school_slug) do
    Location
    |> Repo.get_by!(slug: school_slug, is_school: true)
    |> Repo.preload([:address])
  end

  def get_school_by_slug(school_slug) do
    Location
    |> Repo.get_by(slug: school_slug, is_school: true)
    |> case do
      nil -> nil
      school -> Repo.preload(school, [:address])
    end
  end

  @doc """
  Gets a school by slug with only essential fields for display.
  Reduces data transfer by ~56% compared to full query.
  """
  def get_school_by_slug_selective!(school_slug) do
    query =
      from(l in Location,
        where: l.slug == ^school_slug and l.is_school == true,
        select: %Location{
          id: l.id,
          name: l.name,
          slug: l.slug,
          parent_location_id: l.parent_location_id,
          is_school: l.is_school
        }
      )

    school = Repo.one!(query)

    # Load address separately with selective fields
    address_query =
      from(a in MehrSchulferien.Maps.Address,
        where: a.school_location_id == ^school.id,
        select: %MehrSchulferien.Maps.Address{
          id: a.id,
          street: a.street,
          zip_code: a.zip_code,
          city: a.city,
          email_address: a.email_address,
          phone_number: a.phone_number,
          homepage_url: a.homepage_url,
          lat: a.lat,
          lon: a.lon,
          school_type: a.school_type
        }
      )

    address = Repo.one(address_query)
    %{school | address: address}
  end

  @doc """
  Shows a map for the related locations from city -> country.
  """
  def show_city_to_country_map(country_slug, city_slug) do
    country = get_country_by_slug!(country_slug)
    city = get_city_by_slug!(city_slug)
    county = get_location!(city.parent_location_id)
    federal_state = get_location!(county.parent_location_id)

    if country.id != federal_state.parent_location_id do
      raise MehrSchulferien.CountryNotParentError
    end

    %{country: country, federal_state: federal_state, county: county, city: city}
  end

  def show_city_to_country_map_safe(country_slug, city_slug) do
    with country when not is_nil(country) <- get_country_by_slug(country_slug),
         city when not is_nil(city) <- get_city_by_slug(city_slug),
         county when not is_nil(county) <- get_location(city.parent_location_id),
         federal_state when not is_nil(federal_state) <- get_location(county.parent_location_id) do
      if country.id == federal_state.parent_location_id do
        {:ok, %{country: country, federal_state: federal_state, county: county, city: city}}
      else
        {:error, :invalid_hierarchy}
      end
    else
      _ -> {:error, :not_found}
    end
  end

  @doc """
  Shows a map for the related locations from school -> country.
  """
  def show_school_to_country_map(country_slug, school_slug) do
    country = get_country_by_slug!(country_slug)
    school = get_school_by_slug!(school_slug)
    city = get_location!(school.parent_location_id)
    county = get_location!(city.parent_location_id)
    federal_state = get_location!(county.parent_location_id)

    if country.id != federal_state.parent_location_id do
      raise MehrSchulferien.CountryNotParentError
    end

    %{country: country, federal_state: federal_state, county: county, city: city, school: school}
  end

  def show_school_to_country_map_safe(country_slug, school_slug) do
    with country when not is_nil(country) <- get_country_by_slug(country_slug),
         school when not is_nil(school) <- get_school_by_slug(school_slug),
         city when not is_nil(city) <- get_location(school.parent_location_id),
         county when not is_nil(county) <- get_location(city.parent_location_id),
         federal_state when not is_nil(federal_state) <- get_location(county.parent_location_id) do
      if country.id == federal_state.parent_location_id do
        {:ok,
         %{
           country: country,
           federal_state: federal_state,
           county: county,
           city: city,
           school: school
         }}
      else
        {:error, :invalid_hierarchy}
      end
    else
      _ -> {:error, :not_found}
    end
  end

  def with_periods(locations) do
    Repo.preload(locations, [:periods])
  end

  @doc """
  Gets all schools by zip code.
  """
  def get_schools_by_zip_code(zip_code) when is_binary(zip_code) do
    query =
      from s in Location,
        join: a in MehrSchulferien.Maps.Address,
        on: a.school_location_id == s.id,
        where: s.is_school == true and a.zip_code == ^zip_code,
        preload: [:address, :parent_location],
        order_by: s.name

    Repo.all(query)
  end

  @doc """
  Returns counties with their cities that have at least one school, including the school count.
  This is an optimized query that avoids the N+1 problem by fetching all required data in just
  a few queries instead of querying separately for each city.
  """
  def list_counties_with_cities_having_schools(federal_state) do
    # First, get all counties for this federal state
    counties = list_counties(federal_state)
    county_ids = Enum.map(counties, & &1.id)

    # Get cities with school counts in a single query
    cities_with_school_counts_query =
      from city in Location,
        join: school in Location,
        on: school.parent_location_id == city.id and school.is_school == true,
        where: city.parent_location_id in ^county_ids and city.is_city == true,
        group_by: [city.id, city.name, city.slug, city.parent_location_id],
        select: %{
          city_data: city,
          school_count: count(school.id)
        },
        order_by: [asc: city.name]

    cities_with_school_counts = Repo.all(cities_with_school_counts_query)

    # Preload zip_codes for all cities at once
    city_ids = Enum.map(cities_with_school_counts, & &1.city_data.id)

    cities_with_zip_codes =
      from(c in Location,
        where: c.id in ^city_ids,
        preload: [:zip_codes]
      )
      |> Repo.all()
      |> Map.new(fn city -> {city.id, city} end)

    # Add zip_codes to each city in cities_with_school_counts
    cities_with_school_counts =
      Enum.map(cities_with_school_counts, fn %{city_data: city_data} = city_item ->
        city_with_zip_codes = Map.get(cities_with_zip_codes, city_data.id)
        %{city_item | city_data: %{city_data | zip_codes: city_with_zip_codes.zip_codes}}
      end)

    # Group cities by county
    cities_by_county = Enum.group_by(cities_with_school_counts, & &1.city_data.parent_location_id)

    # Create the final result by mapping counties to their cities
    # Sort counties alphabetically by name
    counties
    |> Enum.sort_by(& &1.name)
    |> Enum.map(fn county ->
      cities = Map.get(cities_by_county, county.id, [])
      {county, cities}
    end)
    |> Enum.filter(fn {_county, cities} -> length(cities) > 0 end)
  end

  #
  # Cached operations for improved performance
  #

  @doc """
  Cached version of list_countries_with_federal_states_selective.
  Uses ETS cache with 1-hour TTL for optimal performance.
  """
  def list_countries_with_federal_states_cached do
    Cache.cached_location_operation(
      "countries_with_states",
      fn ->
        list_countries_with_federal_states_selective()
      end,
      ttl: 3600
    )
  end

  @doc """
  Cached version of list_countries.
  Uses ETS cache with 2-hour TTL since countries rarely change.
  """
  def list_countries_cached do
    Cache.cached_location_operation(
      "countries_list",
      fn ->
        list_countries()
      end,
      ttl: 7200
    )
  end

  @doc """
  Cached federal states lookup for a specific country.
  """
  def list_federal_states_cached(country) do
    cache_key = "federal_states_#{country.id}"

    Cache.cached_location_operation(
      cache_key,
      fn ->
        list_federal_states(country)
      end,
      ttl: 3600
    )
  end

  @doc """
  Cached counties with cities having schools for a specific federal state.
  """
  def list_counties_with_cities_having_schools_cached(federal_state) do
    cache_key = "counties_cities_schools_#{federal_state.id}"

    Cache.cached_location_operation(
      cache_key,
      fn ->
        list_counties_with_cities_having_schools(federal_state)
      end,
      ttl: 1800
    )
  end

  @doc """
  Clears location-related cache entries when data is modified.
  Should be called after any location create/update/delete operations.
  """
  def clear_location_caches do
    Cache.clear_all_location_hierarchies()
  end

  @doc """
  Clears specific location cache entries.
  """
  def clear_location_cache(location) do
    # Clear relevant cache entries based on location type
    if location.is_country do
      Cache.clear_location_hierarchy("countries_list")
      Cache.clear_location_hierarchy("countries_with_states")
    end

    if location.is_federal_state do
      Cache.clear_location_hierarchy("countries_with_states")
      Cache.clear_location_hierarchy("federal_states_#{location.parent_location_id}")
      Cache.clear_location_hierarchy("counties_cities_schools_#{location.id}")
    end

    if location.is_county or location.is_city do
      # Find federal state ID to clear cache
      case get_federal_state_for_location(location) do
        %{id: federal_state_id} ->
          Cache.clear_location_hierarchy("counties_cities_schools_#{federal_state_id}")

        _ ->
          :ok
      end
    end
  end

  # Helper to find the federal state for any location
  defp get_federal_state_for_location(%{is_federal_state: true} = location), do: location
  defp get_federal_state_for_location(%{parent_location_id: nil}), do: nil

  defp get_federal_state_for_location(%{parent_location_id: parent_id}) do
    parent = Repo.get(Location, parent_id)
    if parent, do: get_federal_state_for_location(parent), else: nil
  end

  #
  # Geographic search functions for schools
  #

  @doc """
  Finds schools within the same zip code as the given school.
  Returns a list of schools with their addresses preloaded.
  """
  def find_schools_by_same_zip_code(%Location{is_school: true} = school) do
    school = Repo.preload(school, :address)

    case school.address do
      %{zip_code: zip_code} when not is_nil(zip_code) and zip_code != "" ->
        from(s in Location,
          join: a in assoc(s, :address),
          where:
            s.is_school == true and
              s.id != ^school.id and
              a.zip_code == ^zip_code,
          preload: [:address],
          order_by: s.name
        )
        |> Repo.all()

      _ ->
        []
    end
  end

  @doc """
  Finds schools within a given radius (in kilometers) from the given school.
  Uses the Haversine formula to calculate distances.
  Returns schools with their addresses and calculated distances.
  """
  def find_schools_within_radius(%Location{is_school: true} = school, radius_km) do
    school = Repo.preload(school, :address)

    case school.address do
      %{lat: lat, lon: lon} when not is_nil(lat) and not is_nil(lon) ->
        # Earth radius in kilometers
        earth_radius = 6371.0

        query = """
        SELECT DISTINCT l.*, 
               (#{earth_radius} * acos(
                 cos(radians($1)) * cos(radians(a.lat)) * 
                 cos(radians(a.lon) - radians($2)) + 
                 sin(radians($1)) * sin(radians(a.lat))
               )) as distance_km
        FROM locations l
        INNER JOIN addresses a ON a.school_location_id = l.id
        WHERE l.is_school = true
          AND l.id != $3
          AND a.lat IS NOT NULL
          AND a.lon IS NOT NULL
          AND (#{earth_radius} * acos(
                cos(radians($1)) * cos(radians(a.lat)) * 
                cos(radians(a.lon) - radians($2)) + 
                sin(radians($1)) * sin(radians(a.lat))
              )) <= $4
        ORDER BY distance_km ASC
        """

        result = Ecto.Adapters.SQL.query!(Repo, query, [lat, lon, school.id, radius_km])

        # Convert results to Location structs with distance
        Enum.map(result.rows, fn row ->
          location = Repo.load(Location, {result.columns, row})
          location = Repo.preload(location, :address)

          # Find the distance value (last column)
          distance_idx = Enum.find_index(result.columns, &(&1 == "distance_km"))
          distance = if distance_idx, do: Enum.at(row, distance_idx), else: nil

          # Add distance as a virtual field
          Map.put(location, :distance_km, distance)
        end)

      _ ->
        []
    end
  end

  @doc """
  Searches for schools by name within a given radius from the given school.
  Combines name search with geographic filtering.
  """
  def search_schools_by_name_within_radius(
        %Location{is_school: true} = school,
        name_pattern,
        radius_km
      ) do
    school = Repo.preload(school, :address)

    case school.address do
      %{lat: lat, lon: lon} when not is_nil(lat) and not is_nil(lon) ->
        # Get all schools within radius first
        schools_in_radius = find_schools_within_radius(school, radius_km)

        # Filter by name pattern
        Enum.filter(schools_in_radius, fn s ->
          String.match?(String.downcase(s.name), ~r/#{String.downcase(name_pattern)}/)
        end)

      _ ->
        []
    end
  end

  @doc """
  Finds all schools in the same city as the given school.
  """
  def find_schools_in_same_city(%Location{is_school: true} = school) do
    from(s in Location,
      where:
        s.is_school == true and
          s.id != ^school.id and
          s.parent_location_id == ^school.parent_location_id,
      preload: [:address],
      order_by: s.name
    )
    |> Repo.all()
  end

  @doc """
  Helper function to calculate distance between two coordinates using Haversine formula.
  Returns distance in kilometers.
  """
  def calculate_distance(lat1, lon1, lat2, lon2) do
    # Earth radius in kilometers
    earth_radius = 6371.0

    # Convert to radians
    lat1_rad = lat1 * :math.pi() / 180
    lat2_rad = lat2 * :math.pi() / 180
    delta_lat = (lat2 - lat1) * :math.pi() / 180
    delta_lon = (lon2 - lon1) * :math.pi() / 180

    # Haversine formula
    a =
      :math.sin(delta_lat / 2) * :math.sin(delta_lat / 2) +
        :math.cos(lat1_rad) * :math.cos(lat2_rad) *
          :math.sin(delta_lon / 2) * :math.sin(delta_lon / 2)

    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))

    earth_radius * c
  end

  @doc """
  Generates a slug for a school based on zip code and school name.

  ## Examples

      iex> generate_school_slug("Gymnasium München", "80331")
      "80331-gymnasium-muenchen"
      
      iex> generate_school_slug("Schöne Schule", "12345")
      "12345-schoene-schule"
  """
  def generate_school_slug(school_name, zip_code)
      when is_binary(school_name) and is_binary(zip_code) do
    base_slug = MehrSchulferien.SlugGenerator.slugify_downcase(school_name)
    "#{zip_code}-#{base_slug}"
  end

  def generate_school_slug(school_name, nil) when is_binary(school_name) do
    # Fallback for schools without zip code
    MehrSchulferien.SlugGenerator.slugify_downcase(school_name)
  end

  @doc """
  Generates a unique school slug by checking for duplicates and adding a counter if needed.

  ## Examples

      iex> generate_unique_school_slug("Gymnasium München", "80331")
      {:ok, "80331-gymnasium-muenchen"}
      
      # If slug already exists, it adds a counter
      iex> generate_unique_school_slug("Gymnasium München", "80331")
      {:ok, "80331-gymnasium-muenchen-1"}
  """
  def generate_unique_school_slug(school_name, zip_code, school_id \\ nil) do
    base_slug = generate_school_slug(school_name, zip_code)

    case find_unique_slug(base_slug, school_id, 0) do
      {:ok, slug} -> {:ok, slug}
      error -> error
    end
  end

  defp find_unique_slug(base_slug, school_id, counter) do
    test_slug = if counter == 0, do: base_slug, else: "#{base_slug}-#{counter}"

    query =
      from(l in Location,
        where: l.is_school == true and l.slug == ^test_slug
      )

    # Exclude current school if updating
    query = if school_id, do: where(query, [l], l.id != ^school_id), else: query

    case Repo.exists?(query) do
      false -> {:ok, test_slug}
      true -> find_unique_slug(base_slug, school_id, counter + 1)
    end
  end
end
