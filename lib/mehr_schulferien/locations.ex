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

    federal_states = Repo.all(federal_states_query) |> Repo.preload([:periods])

    # Group federal states by parent country
    federal_states_by_country = Enum.group_by(federal_states, & &1.parent_location_id)

    # Build a map of country -> federal states
    Enum.map(countries, fn country ->
      country_federal_states = Map.get(federal_states_by_country, country.id, [])
      {country, country_federal_states}
    end)
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
  Returns the list of schools for a certain country.
  """
  # def list_schools_of_country(country) do
  #   city_ids = country |> list_cities_of_country() |> Enum.map(& &1.id)
  #
  #   from(l in Location, where: l.is_school == true and l.parent_location_id in ^city_ids)
  #   |> Repo.all()
  # end

  @doc """
  Returns the total count of schools in the database.
  """
  def count_schools do
    Repo.aggregate(from(l in Location, where: l.is_school == true), :count, :id)
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
  @doc """
  Gets a single city by querying for the slug.

  Raises `Ecto.NoResultsError` if the city does not exist.
  """
  # def get_city_by_slug!(city_slug) do
  #   Location
  #   |> Repo.get_by!(slug: city_slug, is_city: true)
  #   |> Repo.preload([:zip_codes])
  # end

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

    unless country.id == federal_state.parent_location_id do
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

    unless country.id == federal_state.parent_location_id do
      raise MehrSchulferien.CountryNotParentError
    end

    %{country: country, federal_state: federal_state, county: county, city: city, school: school}
  end

  @doc """
  Returns counties with their cities that have at least one school, including the school count.
  This is an optimized query that avoids the N+1 problem by fetching all required data in just
  a few queries instead of querying separately for each city.
  """
  def list_counties_with_cities_having_schools(federal_state) do
    # Step 1: Fetch all counties for the given federal_state.
    # This provides the primary entities around which cities will be grouped.
    counties = list_counties(federal_state)
    county_ids = Enum.map(counties, & &1.id)

    # If there are no counties, no further processing is needed.
    if Enum.empty?(county_ids) do
      []
    else
      # Step 2: Fetch cities that belong to these counties and have at least one school.
      # This is done in a single query that joins cities with schools,
      # groups by city, and counts the schools for each city.
      # It also orders cities by name descendingly.
      cities_with_school_counts_query =
        from city in Location,
          join: school in Location,
          on: school.parent_location_id == city.id and school.is_school == true,
          where: city.parent_location_id in ^county_ids and city.is_city == true,
          group_by: [city.id, city.name, city.slug, city.parent_location_id],
          select: %{
            city_data: city, # Contains the Location struct for the city
            school_count: count(school.id) # Number of schools in this city
          },
          order_by: [desc: city.name]

      cities_with_school_counts = Repo.all(cities_with_school_counts_query)

      # Step 3: Preload zip_codes for all identified cities efficiently.
      # This avoids N+1 queries when accessing zip codes later.
      city_ids_for_zip_preload = Enum.map(cities_with_school_counts, & &1.city_data.id)

      # Create a map of city_id -> city_with_zip_codes for easy lookup.
      cities_by_id_with_zip_codes =
        if Enum.empty?(city_ids_for_zip_preload) do
          %{}
        else
          from(c in Location,
            where: c.id in ^city_ids_for_zip_preload,
            preload: [:zip_codes]
          )
          |> Repo.all()
          |> Map.new(fn city -> {city.id, city} end)
        end

      # Step 4: Merge the zip_code data back into the cities_with_school_counts list.
      # Each city_data entry is updated with its preloaded zip_codes.
      cities_with_school_counts_and_zips =
        Enum.map(cities_with_school_counts, fn %{city_data: city_data} = city_item ->
          city_with_zip_codes = Map.get(cities_by_id_with_zip_codes, city_data.id)
          updated_city_data = %{city_data | zip_codes: city_with_zip_codes.zip_codes}
          %{city_item | city_data: updated_city_data}
        end)

      # Step 5: Group the enriched city data by their parent county ID.
      cities_by_county_id =
        Enum.group_by(cities_with_school_counts_and_zips, & &1.city_data.parent_location_id)

      # Step 6: Construct the final result.
      # Map over the initial list of counties, attaching their respective cities (which now include school counts and zip codes).
      # Finally, filter out any counties that do not have any cities with schools.
      Enum.map(counties, fn county ->
        cities_for_county = Map.get(cities_by_county_id, county.id, [])
        {county, cities_for_county}
      end)
      |> Enum.filter(fn {_county, cities} -> Enum.any?(cities) end)
    end
  end
end
