defmodule MehrSchulferien.Locations do
  @moduledoc """
  The Locations context.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Maps.Location
  alias MehrSchulferien.Repo

  @doc """
  Returns the list of federal states in a country.
  """
  def list_federal_states(country) do
    from(l in Location, where: l.is_federal_state == true and l.parent_location_id == ^country.id)
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
  def get_city_by_slug!(city_slug, _country_slug) do
    Repo.get_by!(Location, slug: city_slug, is_city: true)
  end
end
