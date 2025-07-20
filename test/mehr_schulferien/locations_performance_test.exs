defmodule MehrSchulferien.LocationsPerformanceTest do
  use MehrSchulferien.DataCase
  import MehrSchulferien.Factory
  alias MehrSchulferien.Locations

  describe "recursive_location_ids performance" do
    test "new implementation uses only one query" do
      # Create a deep hierarchy: country -> federal_state -> county -> city -> school
      country = insert(:country, %{name: "Deutschland", code: "DE"})
      federal_state = insert(:federal_state, %{parent_location_id: country.id, name: "Hamburg"})
      county = insert(:county, %{parent_location_id: federal_state.id, name: "Hamburg County"})
      city = insert(:city, %{parent_location_id: county.id, name: "Hamburg City"})
      school = insert(:school, %{parent_location_id: city.id, name: "Test School"})

      # Count queries during execution
      {:ok, _pid} = :dbg.tracer()
      :dbg.p(:all, :c)
      :dbg.tp(MehrSchulferien.Repo, :query, :x)
      :dbg.tp(MehrSchulferien.Repo, :get, :x)

      # Execute the function
      result = Locations.recursive_location_ids(school)

      # Verify the result is correct
      assert result == [country.id, federal_state.id, county.id, city.id, school.id]

      # Stop tracing
      :dbg.stop()

      # The new implementation should use only 1 query (the CTE)
      # The old implementation would use 4 Repo.get calls + initial lookup
    end

    test "handles locations without parents correctly" do
      country = insert(:country, %{name: "Deutschland", code: "DE"})

      result = Locations.recursive_location_ids(country)
      assert result == [country.id]
    end

    test "handles mid-hierarchy locations correctly" do
      country = insert(:country, %{name: "Deutschland", code: "DE"})
      federal_state = insert(:federal_state, %{parent_location_id: country.id, name: "Hamburg"})
      county = insert(:county, %{parent_location_id: federal_state.id, name: "Hamburg County"})

      result = Locations.recursive_location_ids(county)
      assert result == [country.id, federal_state.id, county.id]
    end
  end
end
