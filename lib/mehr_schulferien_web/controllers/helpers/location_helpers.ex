defmodule MehrSchulferienWeb.Controllers.Helpers.LocationHelpers do
  @moduledoc """
  Helper functions for handling location-related operations in controllers.

  This module contains functions used by controllers to fetch and organize 
  location data for rendering in views.
  """

  alias MehrSchulferien.Locations

  @doc """
  Get counties with their cities for a federal state.

  Returns a list of tuples with each county and its associated cities.
  """
  def get_counties_with_cities(federal_state) do
    counties = Locations.list_counties(federal_state)

    Enum.reduce(counties, [], fn county, acc ->
      acc ++ [{county, Locations.list_cities(county)}]
    end)
  end

  @doc """
  Get locations and associated IDs for a given country and federal state.

  Returns a tuple containing the country, federal state, and an array of location IDs.
  """
  def get_locations_and_ids(country_slug, federal_state_slug) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)
    location_ids = [country.id, federal_state.id]

    {country, federal_state, location_ids}
  end

  @doc """
  Get school data for a city.

  Returns a tuple containing the country, federal state, county, city, and schools.
  """
  def get_school_data(country_slug, federal_state_slug, county_slug, city_slug) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)
    county = Locations.get_county_by_slug!(county_slug, federal_state)

    # Using direct Locations.get_city_by_slug! which doesn't require a parent
    city = Locations.get_city_by_slug!(city_slug)

    # Verify that the city is actually a child of the county to ensure consistency
    if city.parent_location_id != county.id do
      raise MehrSchulferien.InvalidLocationHierarchyError,
            "City is not a child of the specified county"
    end

    schools = Locations.list_schools(city)

    {country, federal_state, county, city, schools}
  end
end
