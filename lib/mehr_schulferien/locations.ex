defmodule MehrSchulferien.Locations do
  @moduledoc """
  The Locations context.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Repo

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

  @doc """
  Returns the list of countries.
  """
  def list_countries do
    Repo.all(from l in Location, where: l.is_country == true)
  end

  @doc """
  Returns the list of federal states in a country.
  """
  def list_federal_states(country) do
    from(l in Location, where: l.is_federal_state == true and l.parent_location_id == ^country.id)
    |> Repo.all()
  end

  @doc """
  Returns the list of counties for a certain federal_state.
  """
  def list_counties(federal_state) do
    from(l in Location, where: l.is_county == true and l.parent_location_id == ^federal_state.id)
    |> Repo.all()
  end

  @doc """
  Returns the list of cities for a certain county.
  """
  def list_cities(county) do
    from(l in Location, where: l.is_city == true and l.parent_location_id == ^county.id)
    |> Repo.all()
    |> Repo.preload([:zip_codes])
    |> Enum.sort(&(&1.name >= &2.name))
  end

  @doc """
  Returns the list of cities for a certain federal_state.
  """
  def list_cities_of_federal_state(federal_state) do
    counties =
      from(l in Location, where: l.is_county == true and l.parent_location_id == ^federal_state.id)
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

  @doc """
  Returns the list of schools for a certain city.
  """
  def list_schools(city) do
    from(l in Location, where: l.is_school == true and l.parent_location_id == ^city.id)
    |> Repo.all()
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
  Returns the total number of schools in the database.
  """
  def number_schools do
    Repo.aggregate(from(l in Location, where: l.is_school == true), :count, :id)
  end

  @doc """
  Returns the total number of schools for a city.
  """
  def number_schools(city) do
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

  def with_periods(locations) do
    Repo.preload(locations, [:periods])
  end
end
