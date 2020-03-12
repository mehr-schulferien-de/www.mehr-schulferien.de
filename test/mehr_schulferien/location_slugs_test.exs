defmodule MehrSchulferien.LocationSlugsTest do
  use MehrSchulferien.DataCase

  alias MehrSchulferien.Locations

  setup do
    country_attrs = %{name: "Deutschland", code: "D", is_country: true}
    {:ok, country} = Locations.create_location(country_attrs)
    {:ok, %{country: country}}
  end

  describe "base slugs" do
    test "default slug is simple" do
    end
  end

  describe "unique slugs" do
    test "slugs are unique for location type", %{country: country} do
      attrs = %{
        is_federal_state: true,
        name: "Berlin",
        code: "BE",
        slug: "berlin",
        parent_location_id: country.id
      }

      {:ok, federal_state} = Locations.create_location(attrs)
      assert federal_state.slug == "berlin"

      attrs = %{
        is_federal_state: true,
        name: "Berliner",
        code: "BE",
        slug: "berlin",
        parent_location_id: country.id
      }

      {:ok, federal_state} = Locations.create_location(attrs)
      assert federal_state.slug == "berlin-be"

      attrs = %{
        is_county: true,
        name: "Berrlin",
        code: "BE",
        slug: "berlin",
        parent_location_id: federal_state.id
      }

      {:ok, county} = Locations.create_location(attrs)
      assert county.slug == "berlin"

      attrs = %{
        is_county: true,
        name: "Berrrlin",
        code: "BE",
        slug: "berlin",
        parent_location_id: federal_state.id
      }

      {:ok, county} = Locations.create_location(attrs)
      assert county.slug == "berlin-be"

      attrs = %{
        is_city: true,
        name: "Beerlin",
        code: "BE",
        slug: "berlin",
        parent_location_id: county.id
      }

      {:ok, city} = Locations.create_location(attrs)
      assert city.slug == "berlin"

      attrs = %{
        is_federal_state: false,
        is_city: true,
        name: "Beeerlin",
        code: "BE",
        slug: "berlin",
        parent_location_id: city.id
      }

      {:ok, city} = Locations.create_location(attrs)
      assert city.slug == "berlin-be"

      attrs = %{
        is_federal_state: false,
        is_city: true,
        name: "Beeeerlin",
        code: "BE",
        slug: "berlin",
        parent_location_id: city.id
      }

      {:ok, city} = Locations.create_location(attrs)
      assert city.slug == "berlin-be-1"

      attrs = %{
        is_federal_state: false,
        is_city: true,
        name: "Beeeeerlin",
        code: "BE",
        slug: "berlin",
        parent_location_id: city.id
      }

      {:ok, city} = Locations.create_location(attrs)
      assert city.slug == "berlin-be-2"

      attrs = %{
        is_federal_state: false,
        is_city: true,
        name: "Beeeeeerlin",
        code: "BE",
        slug: "berlin",
        parent_location_id: city.id
      }

      {:ok, city} = Locations.create_location(attrs)
      assert city.slug == "berlin-be-3"
    end
  end
end
