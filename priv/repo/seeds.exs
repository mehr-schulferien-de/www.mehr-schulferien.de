# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MehrSchulferien.Repo.insert!(%MehrSchulferien.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query
alias MehrSchulferien.Locations
alias MehrSchulferien.Locations.City
alias MehrSchulferien.Locations.ZipCode
alias MehrSchulferien.Repo

# Countries
#
{:ok, deutschland} = Locations.create_country(%{name: "Deutschland"})

# Create the federal_states of Deutschland
#
{:ok, _badenwuerttemberg} =
  Locations.create_federal_state(%{
    name: "Baden-Württemberg",
    code: "BW",
    country_id: deutschland.id
  })

{:ok, _bayern} =
  Locations.create_federal_state(%{name: "Bayern", code: "BY", country_id: deutschland.id})

{:ok, _berlin} =
  Locations.create_federal_state(%{name: "Berlin", code: "BE", country_id: deutschland.id})

{:ok, _brandenburg} =
  Locations.create_federal_state(%{name: "Brandenburg", code: "BB", country_id: deutschland.id})

{:ok, _bremen} =
  Locations.create_federal_state(%{name: "Bremen", code: "HB", country_id: deutschland.id})

{:ok, _hamburg} =
  Locations.create_federal_state(%{name: "Hamburg", code: "HH", country_id: deutschland.id})

{:ok, _hessen} =
  Locations.create_federal_state(%{name: "Hessen", code: "HE", country_id: deutschland.id})

{:ok, _mecklenburgvorpommern} =
  Locations.create_federal_state(%{
    name: "Mecklenburg-Vorpommern",
    code: "MV",
    country_id: deutschland.id
  })

{:ok, _niedersachsen} =
  Locations.create_federal_state(%{name: "Niedersachsen", code: "NI", country_id: deutschland.id})

{:ok, _nordrheinwestfalen} =
  Locations.create_federal_state(%{
    name: "Nordrhein-Westfalen",
    code: "NW",
    country_id: deutschland.id
  })

{:ok, _rheinlandpfalz} =
  Locations.create_federal_state(%{
    name: "Rheinland-Pfalz",
    code: "RP",
    country_id: deutschland.id
  })

{:ok, _saarland} =
  Locations.create_federal_state(%{name: "Saarland", code: "SL", country_id: deutschland.id})

{:ok, _sachsen} =
  Locations.create_federal_state(%{name: "Sachsen", code: "SN", country_id: deutschland.id})

{:ok, _sachsenanhalt} =
  Locations.create_federal_state(%{name: "Sachsen-Anhalt", code: "ST", country_id: deutschland.id})

{:ok, _schleswigholstein} =
  Locations.create_federal_state(%{
    name: "Schleswig-Holstein",
    code: "SH",
    country_id: deutschland.id
  })

{:ok, _thueringen} =
  Locations.create_federal_state(%{name: "Thüringen", code: "TH", country_id: deutschland.id})

# Create cities
#
File.stream!("priv/repo/city-seeds.json")
|> Stream.map(&String.replace(&1, "\n", ""))
|> Stream.with_index()
|> Enum.each(fn {contents, _line_num} ->
  city_json = Poison.decode!(contents)
  city_name = city_json["name"]
  zip_code_value = city_json["zip_code"]
  zip_code_like_query = String.slice(zip_code_value, 0, 1) <> "%"
  federal_state = Locations.get_federal_state!(city_json["federal_state_slug"])
  country = Locations.get_country!(city_json["country_slug"])

  query =
    from c in City,
      join: z in ZipCode,
      on: c.id == z.city_id,
      where: c.name == ^city_name,
      where: like(z.value, ^zip_code_like_query),
      limit: 1

  city = Repo.one(query) |> Repo.preload([:zip_codes])

  case city do
    nil ->
      Locations.create_city(%{
        name: city_name,
        country_id: country.id,
        federal_state_id: federal_state.id,
        zip_codes: [%ZipCode{value: zip_code_value, country_id: country.id}]
      })

    _ ->
      Locations.create_zip_code(%{value: zip_code_value, country_id: country.id, city_id: city.id})
  end
end)
