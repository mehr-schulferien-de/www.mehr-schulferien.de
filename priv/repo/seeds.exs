# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias MehrSchulferien.Maps
alias MehrSchulferien.Calendars

# Countries
#
{:ok, deutschland} = Maps.create_location(%{name: "Deutschland", code: "D", is_country: true})

# Create the federal_states of Deutschland
#
{:ok, _badenwuerttemberg} =
  Maps.create_location(%{
    name: "Baden-Württemberg",
    code: "BW",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _bayern} =
  Maps.create_location(%{
    name: "Bayern",
    code: "BY",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _berlin} =
  Maps.create_location(%{
    name: "Berlin",
    code: "BE",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _brandenburg} =
  Maps.create_location(%{
    name: "Brandenburg",
    code: "BB",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _bremen} =
  Maps.create_location(%{
    name: "Bremen",
    code: "HB",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _hamburg} =
  Maps.create_location(%{
    name: "Hamburg",
    code: "HH",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _hessen} =
  Maps.create_location(%{
    name: "Hessen",
    code: "HE",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _mecklenburgvorpommern} =
  Maps.create_location(%{
    name: "Mecklenburg-Vorpommern",
    code: "MV",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _niedersachsen} =
  Maps.create_location(%{
    name: "Niedersachsen",
    code: "NI",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _nordrheinwestfalen} =
  Maps.create_location(%{
    name: "Nordrhein-Westfalen",
    code: "NW",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _rheinlandpfalz} =
  Maps.create_location(%{
    name: "Rheinland-Pfalz",
    code: "RP",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _saarland} =
  Maps.create_location(%{
    name: "Saarland",
    code: "SL",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _sachsen} =
  Maps.create_location(%{
    name: "Sachsen",
    code: "SN",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _sachsenanhalt} =
  Maps.create_location(%{
    name: "Sachsen-Anhalt",
    code: "ST",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _schleswigholstein} =
  Maps.create_location(%{
    name: "Schleswig-Holstein",
    code: "SH",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _thueringen} =
  Maps.create_location(%{
    name: "Thüringen",
    code: "TH",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

# Seeds religions
#
{:ok, _christentum} =
  Calendars.create_religion(%{
    name: "Christentum",
    wikipedia_url: "https://de.wikipedia.org/wiki/Christentum"
  })

{:ok, _judentum} =
  Calendars.create_religion(%{
    name: "Judentum",
    wikipedia_url: "https://de.wikipedia.org/wiki/Judentum"
  })

{:ok, _islam} =
  Calendars.create_religion(%{name: "Islam", wikipedia_url: "https://de.wikipedia.org/wiki/Islam"})
