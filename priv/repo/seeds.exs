# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias MehrSchulferien.Maps

# Countries
#
{:ok, deutschland} = Maps.create_location(%{name: "Deutschland", code: "D"})

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
