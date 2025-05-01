defmodule MehrSchulferien.Locations.Specialized do
  @moduledoc """
  Specialized operations for locations.

  This module contains functions for specialized location operations like hierarchical
  lookups and locations by specific type and slug.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Locations.{Location, Query}
  alias MehrSchulferien.Repo

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

  @doc """
  Gets a single federal_state.

  Raises `Ecto.NoResultsError` if the federal state does not exist.
  """
  def get_federal_state!(id) do
    Repo.get_by!(Location, id: id, is_federal_state: true)
  end

  @doc """
  Gets a single country by querying for the slug.

  Raises `Ecto.NoResultsError` if the country does not exist.
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
    county = Query.get_location!(city.parent_location_id)
    federal_state = Query.get_location!(county.parent_location_id)

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
    city = Query.get_location!(school.parent_location_id)
    county = Query.get_location!(city.parent_location_id)
    federal_state = Query.get_location!(county.parent_location_id)

    unless country.id == federal_state.parent_location_id do
      raise MehrSchulferien.CountryNotParentError
    end

    %{country: country, federal_state: federal_state, county: county, city: city, school: school}
  end

  @doc """
  Combines periods from schools and their parent cities.
  """
  def combine_school_periods(schools, cities) do
    Enum.map(schools, fn school ->
      city = Enum.find(cities, &(&1.id == school.parent_location_id))
      %Location{school | periods: school.periods ++ city.periods}
    end)
  end
end
