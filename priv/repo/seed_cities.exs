# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seed_cities.exs

import Ecto.Query
alias MehrSchulferien.Repo
alias MehrSchulferien.Maps
alias MehrSchulferien.Maps.Location
alias MehrSchulferien.Maps.ZipCode

# Only seed an empty city table.
#
city_count = Repo.one(from l in Location, where: l.is_city == true, select: count(l.id))

if city_count != 0 do
  IO.puts("There are already elements in the cities table.")
else
  zip_codes = "priv/repo/seeds.d/zip_codes.json" |> File.read!() |> Poison.decode!()

  zip_codes
  |> Enum.each(fn city ->
    # Find FederalState
    #
    json_federal_state = city["state"]

    query =
      from l in Location,
        where: l.name == ^json_federal_state,
        where: l.is_federal_state == true,
        limit: 1

    federal_state = Repo.one(query)

    # Find or create County
    #
    json_county = 
      city["community"]
      |> String.replace(", kreisfreie Stadt", "")
      |> String.replace(", Stadt", "")

    query =
      from l in Location,
        where: l.name == ^json_county,
        where: l.is_county == true,
        where: l.parent_location_id == ^federal_state.id,
        limit: 1

    county = case Repo.one(query) do
      nil ->
        {:ok, county} =
          Maps.create_location(%{
            name: json_county,
            is_county: true,
            parent_location_id: federal_state.id,
            cachable_calendar_location_id: federal_state.id
          })
        county
      county ->
        county
    end

    # Find or create ZipCode
    #
    json_zip_code = city["zipcode"]

    query =
    from z in ZipCode,
      where: z.value == ^json_zip_code,
      where: z.country_location_id == ^federal_state.parent_location_id,
      limit: 1

    case Repo.one(query) do
      nil ->
        {:ok, zip_code} =
          Maps.create_zip_code(%{
            value: json_zip_code,
            country_location_id: federal_state.parent_location_id
          })
        zip_code
      zip_code ->
        zip_code
    end

    # Create City
    # 
    json_city = city["city"]
    json_latitude = city["latitude"]
    json_longitude = city["longitude"]

    query =
      from l in Location,
        where: l.name == ^json_city,
        where: l.is_city == true,
        where: l.parent_location_id == ^county.id,
        limit: 1

    city = case Repo.one(query) do
      nil ->
        {:ok, city} =
          Maps.create_location(%{
            name: json_city,
            is_city: true,
            cachable_calendar_location_id: federal_state.id,
            parent_location_id: county.id
          })
        city
      city ->
        city
    end

    # # TODO: Use lat and lon to narrow down similar cities
    # query =
    # from c in City,
    #   where: c.name == ^json_city, 
    #   where: c.federal_state_id == ^federal_state.id,
    #   where: c.country_id == ^federal_state.country_id,
    #   limit: 1

    # case Repo.one(query) do
    #   nil ->
    #     {:ok, _city} =
    #       Locations.create_city(%{
    #         name: json_city,
    #         county_id: county.id,
    #         federal_state_id: federal_state.id,
    #         country_id: federal_state.country_id
    #       })

    #   _ ->
    #     nil
    # end    

    # city = Repo.one(query) 

    # {:ok, _zip_code_mapping} = Locations.create_zip_code_mapping(%{
    #   city_id: city.id,
    #   zip_code_id: zip_code.id,
    #   lat: json_latitude,
    #   lon: json_longitude
    # })
  end)

  # city_count = Repo.one(from p in "cities", select: count(p.id))
  # IO.puts("Seeded cities: " <> Integer.to_string(city_count))
end
