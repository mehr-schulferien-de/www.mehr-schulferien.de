defmodule MehrSchulferien.Locations.Query do
  @moduledoc """
  Location query operations.

  This module handles querying operations for locations.
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

  defp combine_city_periods(federal_state, counties, city) do
    county = Enum.find(counties, &(&1.id == city.parent_location_id))
    periods = federal_state.periods ++ county.periods ++ city.periods
    %Location{city | periods: periods}
  end

  @doc """
  Adds periods to locations by preloading the periods association.
  """
  def with_periods(locations) do
    Repo.preload(locations, [:periods])
  end
end
