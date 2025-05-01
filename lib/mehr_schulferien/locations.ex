defmodule MehrSchulferien.Locations do
  @moduledoc """
  The Locations context.

  This module handles all operations related to geographic locations in the application,
  including countries, federal states, counties, cities, and schools. It provides functions
  for querying, creating, updating, and deleting locations, as well as specialized queries
  for different location types and their hierarchical relationships.
  """

  alias MehrSchulferien.Locations.{
    Query,
    CRUD,
    Specialized
  }

  # CRUD operations
  defdelegate list_locations, to: Query
  defdelegate get_location!(id), to: Query
  defdelegate get_location_by_slug!(slug), to: Query
  defdelegate create_location(attrs \\ %{}), to: CRUD
  defdelegate update_location(location, attrs), to: CRUD
  defdelegate delete_location(location), to: CRUD
  defdelegate change_location(location), to: CRUD

  # Hierarchical operations
  defdelegate recursive_location_ids(location), to: Specialized

  # Location type queries
  defdelegate list_countries, to: Query
  defdelegate list_federal_states(country), to: Query
  defdelegate list_counties(federal_state), to: Query
  defdelegate list_cities(county), to: Query
  defdelegate list_cities_of_federal_state(federal_state), to: Query
  defdelegate list_cities_of_country(country), to: Query
  defdelegate list_schools(city), to: Query
  defdelegate list_schools_of_country(country), to: Query
  defdelegate number_schools, to: Query
  defdelegate number_schools(city), to: Query
  defdelegate with_periods(locations), to: Query

  # Specialized operations by slug
  defdelegate get_federal_state!(id), to: Specialized
  defdelegate get_country_by_slug!(country_slug), to: Specialized
  defdelegate get_federal_state_by_slug!(federal_state_slug, country), to: Specialized
  defdelegate get_county_by_slug!(county_slug, federal_state), to: Specialized
  defdelegate get_city_by_slug!(city_slug), to: Specialized
  defdelegate get_school_by_slug!(school_slug), to: Specialized
  defdelegate show_city_to_country_map(country_slug, city_slug), to: Specialized
  defdelegate show_school_to_country_map(country_slug, school_slug), to: Specialized
  defdelegate combine_school_periods(schools, cities), to: Specialized
end
