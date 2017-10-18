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

alias MehrSchulferien.Locations
alias MehrSchulferien.Timetables
import Ecto.Query

# Locations
#
{:ok, deutschland} = Locations.create_country(%{name: "Deutschland"})

# Create the federal states of Germany
#
{:ok, _badenwuerttemberg} = Locations.create_federal_state(%{name: "Baden-Württemberg", code: "BW", country_id: deutschland.id})
{:ok, _bayern} = Locations.create_federal_state(%{name: "Bayern", code: "BY", country_id: deutschland.id})
{:ok, _berlin} = Locations.create_federal_state(%{name: "Berlin", code: "BE", country_id: deutschland.id})
{:ok, _brandenburg} = Locations.create_federal_state(%{name: "Brandenburg", code: "BB", country_id: deutschland.id})
{:ok, _bremen} = Locations.create_federal_state(%{name: "Bremen", code: "HB", country_id: deutschland.id})
{:ok, _hamburg} = Locations.create_federal_state(%{name: "Hamburg", code: "HH", country_id: deutschland.id})
{:ok, _hessen} = Locations.create_federal_state(%{name: "Hessen", code: "HE", country_id: deutschland.id})
{:ok, _mecklenburgvorpommern} = Locations.create_federal_state(%{name: "Mecklenburg-Vorpommern", code: "MV", country_id: deutschland.id})
{:ok, _niedersachsen} = Locations.create_federal_state(%{name: "Niedersachsen", code: "NI", country_id: deutschland.id})
{:ok, _nordrheinwestfalen} = Locations.create_federal_state(%{name: "Nordrhein-Westfalen", code: "NW", country_id: deutschland.id})
{:ok, _rheinlandpfalz} = Locations.create_federal_state(%{name: "Rheinland-Pfalz", code: "RP", country_id: deutschland.id})
{:ok, _saarland} = Locations.create_federal_state(%{name: "Saarland", code: "SL", country_id: deutschland.id})
{:ok, _sachsen} = Locations.create_federal_state(%{name: "Sachsen", code: "SN", country_id: deutschland.id})
{:ok, _sachsenanhalt} = Locations.create_federal_state(%{name: "Sachsen-Anhalt", code: "ST", country_id: deutschland.id})
{:ok, _schleswigholstein} = Locations.create_federal_state(%{name: "Schleswig-Holstein", code: "SH", country_id: deutschland.id})
{:ok, _thueringen} = Locations.create_federal_state(%{name: "Thüringen", code: "TH", country_id: deutschland.id})

# Import cities
#
File.stream!("priv/repo/city-seeds.json") |>
Stream.map( &(String.replace(&1, "\n", "")) ) |>
Stream.with_index |>
Enum.each( fn({contents, line_num}) ->
  city = Poison.decode!(contents)
  federal_state = Locations.get_federal_state!(city["federal_state_slug"])
  country = Locations.get_country!(city["country_slug"])
  Locations.create_city(%{name: city["name"], slug: city["slug"], zip_code: city["zip_code"], country_id: country.id, federal_state_id: federal_state.id})
end)

# Import schools
#
File.stream!("priv/repo/school-seeds.json") |>
Stream.map( &(String.replace(&1, "\n", "")) ) |>
Stream.with_index |>
Enum.each( fn({contents, line_num}) ->
  school = Poison.decode!(contents)
  city = Locations.get_city!(school["city_slug"])
  federal_state = Locations.get_federal_state!(school["federal_state_slug"])
  country = Locations.get_country!(school["country_slug"])
  Locations.create_school(%{name: school["name"], slug: school["slug"],
                            address_zip_code: school["address_zip_code"],
                            address_line1: school["address_line1"],
                            address_line2: school["address_line2"],
                            address_street: school["address_street"],
                            address_zip_code: school["address_zip_code"],
                            address_city: school["address_city"],
                            email_address: school["email_address"],
                            homepage_url: school["homepage_url"],
                            phone_number: school["phone_number"],
                            fax_number: school["fax_number"],
                            city_id: city.id,
                            country_id: country.id,
                            federal_state_id: federal_state.id})
end)

# Years 2016-2025
#
Enum.each (2016..2025), fn year_number ->
  case Timetables.create_year(%{value: year_number}) do
    {:ok, year} ->
      {:ok, first_day} = Date.from_erl({year_number, 1, 1})
      Enum.each (0..366), fn counter ->
        day = Date.add(first_day, counter)
        case day.year do
          ^year_number ->
            case day.day do
              1 -> {:ok, month} = Timetables.create_month(%{value: day.month, year_id: year.id})
              _ -> query = from m in Timetables.Month, where: m.value == ^day.month, where: m.year_id == ^year.id
                   month = MehrSchulferien.Repo.one(query)
            end

            Timetables.create_day(%{value: day})
          _ -> nil
        end
      _ -> nil
    end
  end
end
