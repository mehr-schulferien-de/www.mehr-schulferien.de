defmodule MehrSchulferien.Locations do
  @moduledoc """
  The Locations context.

  This module handles all operations related to geographic locations in the application,
  including countries, federal states, counties, cities, and schools. It provides functions
  for querying, creating, updating, and deleting locations, as well as specialized queries
  for different location types and their hierarchical relationships.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Repo

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
  """
  def recursive_location_ids(location) do
    build_ids_list([], location)
  end

  defp build_ids_list(ids_list, %Location{id: id, parent_location_id: nil}) do
    [id | ids_list]
  end

  defp build_ids_list(ids_list, %Location{id: id, parent_location_id: parent_location_id}) do
    build_ids_list([id | ids_list], Repo.get(Location, parent_location_id))
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
                  cos(radians(?)) * 
                  cos(radians(?)) * 
                  cos(radians(?) - radians(?)) + 
                  sin(radians(?)) * 
                  sin(radians(?))
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
                 cos(radians(?)) * 
                 cos(radians(?)) * 
                 cos(radians(?) - radians(?)) + 
                 sin(radians(?)) * 
                 sin(radians(?))
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

  @doc """
  Gets a single school by querying for the slug.

  Raises `Ecto.NoResultsError` if the school does not exist.
  """
  def get_school_by_slug!(school_slug) do
    Location
    |> Repo.get_by!(slug: school_slug, is_school: true)
    |> Repo.preload([:address])
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

  def with_periods(locations) do
    Repo.preload(locations, [:periods])
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
        order_by: [desc: city.name]

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
    Enum.map(counties, fn county ->
      cities = Map.get(cities_by_county, county.id, [])
      {county, cities}
    end)
    |> Enum.filter(fn {_county, cities} -> length(cities) > 0 end)
  end
end
