defmodule MehrSchulferien.TestHelpers do
  @moduledoc """
  Helper functions for tests to handle common operations like
  getting or creating test data.
  """

  import MehrSchulferien.Factory
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Repo

  @doc """
  Gets the existing Deutschland country from the seeded database,
  or creates a new one if it doesn't exist.

  This helps avoid unique constraint violations in tests when
  the database already has seeded data.
  """
  def get_or_create_deutschland do
    Repo.get_by(Location, slug: "d", is_country: true) ||
      insert(:country, %{slug: "d", name: "Deutschland", code: "D"})
  end

  @doc """
  Gets the existing Switzerland country from the seeded database,
  or creates a new one if it doesn't exist.

  This helps avoid unique constraint violations in tests when
  the database already has seeded data.
  """
  def get_or_create_switzerland do
    Repo.get_by(Location, slug: "ch", is_country: true) ||
      insert(:country, %{slug: "ch", name: "Schweiz", code: "CH"})
  end

  @doc """
  Gets or creates a country by slug.
  """
  def get_or_create_country(slug) do
    case slug do
      "d" -> get_or_create_deutschland()
      "ch" -> get_or_create_switzerland()
      _ -> raise ArgumentError, "Unknown country slug: #{slug}"
    end
  end

  @doc """
  Creates a school with the full location hierarchy for testing.
  This is used as a setup function in many tests.
  """
  def create_school(_context \\ %{}) do
    # Create the location hierarchy needed for a school
    country = get_or_create_deutschland()

    federal_state =
      insert(:federal_state, %{
        parent_location_id: country.id,
        slug: "rheinland-pfalz",
        name: "Rheinland-Pfalz"
      })

    county =
      insert(:county, %{
        parent_location_id: federal_state.id,
        slug: "koblenz",
        name: "Koblenz"
      })

    city =
      insert(:city, %{
        parent_location_id: county.id,
        slug: "koblenz-stadt",
        name: "Koblenz"
      })

    school =
      insert(:school, %{
        parent_location_id: city.id,
        slug: "test-gymnasium",
        name: "Test-Gymnasium"
      })

    {:ok,
     %{
       country: country,
       federal_state: federal_state,
       county: county,
       city: city,
       school: school
     }}
  end

  @doc """
  Creates a standard location hierarchy for API tests (Deutschland → Bayern).
  This is the common setup used across all API v2.1 controller tests.

  Returns a map with :country and :federal_state keys.
  """
  def setup_api_test_hierarchy do
    country = get_or_create_deutschland()

    federal_state =
      insert(:federal_state, %{
        name: "Bayern",
        slug: "bayern",
        parent_location_id: country.id
      })

    %{country: country, federal_state: federal_state}
  end

  @doc """
  Creates a complete location hierarchy for testing cities
  (Deutschland → Bayern → München county).

  Returns a map with :country, :federal_state, and :county keys.
  """
  def setup_city_test_hierarchy do
    %{country: country, federal_state: federal_state} = setup_api_test_hierarchy()

    county =
      insert(:county, %{
        name: "München",
        slug: "muenchen-landkreis",
        parent_location_id: federal_state.id
      })

    %{country: country, federal_state: federal_state, county: county}
  end
end
