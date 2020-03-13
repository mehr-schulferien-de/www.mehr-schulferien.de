# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds-schools.exs

defmodule M do
  import Ecto.Query
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Maps
  alias MehrSchulferien.Maps.ZipCode
  alias MehrSchulferien.Maps.ZipCodeMapping

  def import_json do
    "priv/repo/seeds.d/schools.json"
    |> File.read!()
    |> Jason.decode!()
    |> Enum.each(fn school_attrs ->
      federal_state = find_federal_state(school_attrs["federal_state"]["name"])
      slug = school_attrs["slug"]
      name = school_attrs["name"]

      city_name = school_attrs["city"]["name"]
      city_zip_code = school_attrs["city"]["zip_code"]

      city =
        case find_city(city_name, city_zip_code) do
          nil ->
            case find_city_by_zip_code(city_zip_code) do
              nil ->
                fuzzy_find_city(city_name, city_zip_code)

              city ->
                city
            end

          city ->
            city
        end

      {:ok, school} =
        Locations.create_location(%{
          name: name,
          slug: slug,
          parent_location_id: city.id,
          is_school: true,
          cachable_calendar_location_id: federal_state.id
        })

      attrs = Map.put(school_attrs, "school_location_id", school.id)
      Maps.create_address(attrs)
    end)
  end

  def find_city(name, zip_code) do
    query =
      from(location in Location,
        join: zip_code in ZipCode,
        join: zip_code_mapping in ZipCodeMapping,
        on:
          zip_code_mapping.location_id == location.id and
            zip_code_mapping.zip_code_id == zip_code.id,
        where:
          location.name == ^name and zip_code.value == ^zip_code and location.is_city == true,
        limit: 1
      )

    Repo.one(query)
  end

  def find_city_by_zip_code(zip_code) do
    query =
      from(location in Location,
        join: zip_code in ZipCode,
        join: zip_code_mapping in ZipCodeMapping,
        on:
          zip_code_mapping.location_id == location.id and
            zip_code_mapping.zip_code_id == zip_code.id,
        where: zip_code.value == ^zip_code and location.is_city == true,
        limit: 1
      )

    Repo.one(query)
  end

  def fuzzy_find_city(name, zip_code) do
    zip_code_beginning = String.slice(zip_code, 0..3)

    query =
      from(location in Location,
        join: zip_code in ZipCode,
        join: zip_code_mapping in ZipCodeMapping,
        on:
          zip_code_mapping.location_id == location.id and
            zip_code_mapping.zip_code_id == zip_code.id,
        where:
          like(zip_code.value, ^"%#{zip_code_beginning}%") and
            location.name == ^name and location.is_city == true,
        limit: 1
      )

    Repo.one(query)
  end

  def find_federal_state(name) do
    query =
      from(l in Location,
        where: l.name == ^name,
        where: l.is_federal_state == true,
        limit: 1
      )

    Repo.one(query)
  end
end

M.import_json()

# {
#   "name": "Schubart-Gymnasium Partnerschule für Europa",
#   "slug": "73430-schubart-gymnasium-partnerschule-fuer-europa",
#   "address_line1": "Schubart-Gymnasium Partnerschule für Europa",
#   "address_line2": null,
#   "address_street": "Rombacher Straße 30",
#   "address_zip_code": "73430",
#   "address_city": "Aalen",
#   "email_address": null,
#   "phone_number": "+49 7361 9561",
#   "fax_number": "+49 7361 9561",
#   "homepage_url": null,
#   "school_type_entity": "Gymnasium",
#   "school_type": "Gymnasium",
#   "official_id": "75774",
#   "lon": 10.08184,
#   "lat": 48.838598,
#   "city": {
#     "name": "Aalen",
#     "zip_code": "73430"
#   },
#   "federal_state": {
#     "name": "Baden-Württemberg"
#   }
# },
