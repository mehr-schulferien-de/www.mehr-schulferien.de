defmodule MehrSchulferien.LocationsTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory

  alias MehrSchulferien.Locations

  describe "federal state data" do
    test "list_federal_states/1 returns a certain country's federal states" do
      country = insert(:country)
      federal_states = insert_list(3, :federal_state, %{parent_location_id: country.id})
      locations = Locations.list_federal_states(country)
      assert Enum.map(federal_states, & &1.id) == Enum.map(locations, & &1.id)
      assert Enum.filter(locations, &(&1.parent_location_id == country.id))
    end
  end

  describe "city data" do
    test "list_cities/1 returns a certain county's cities" do
      county = insert(:county)
      cities = insert_list(3, :city, %{parent_location_id: county.id})
      cities_ids = cities |> Enum.sort(&(&1.name >= &2.name)) |> Enum.map(& &1.id)
      _other_city = insert(:city)
      cities_1 = Locations.list_cities(county)
      cities_1_ids = Enum.map(cities_1, & &1.id)
      assert cities_1_ids == cities_ids
    end
  end
end