# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias MehrSchulferien.Locations
alias MehrSchulferien.Calendars

# Countries
#
{:ok, deutschland} =
  Locations.create_location(%{name: "Deutschland", code: "D", is_country: true, slug: "d"})

# Create the federal_states of Deutschland
#
{:ok, _badenwuerttemberg} =
  Locations.create_location(%{
    name: "Baden-Württemberg",
    code: "BW",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _bayern} =
  Locations.create_location(%{
    name: "Bayern",
    code: "BY",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _berlin} =
  Locations.create_location(%{
    name: "Berlin",
    code: "BE",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _brandenburg} =
  Locations.create_location(%{
    name: "Brandenburg",
    code: "BB",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _bremen} =
  Locations.create_location(%{
    name: "Bremen",
    code: "HB",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _hamburg} =
  Locations.create_location(%{
    name: "Hamburg",
    code: "HH",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _hessen} =
  Locations.create_location(%{
    name: "Hessen",
    code: "HE",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _mecklenburgvorpommern} =
  Locations.create_location(%{
    name: "Mecklenburg-Vorpommern",
    code: "MV",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _niedersachsen} =
  Locations.create_location(%{
    name: "Niedersachsen",
    code: "NI",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _nordrheinwestfalen} =
  Locations.create_location(%{
    name: "Nordrhein-Westfalen",
    code: "NW",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _rheinlandpfalz} =
  Locations.create_location(%{
    name: "Rheinland-Pfalz",
    code: "RP",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _saarland} =
  Locations.create_location(%{
    name: "Saarland",
    code: "SL",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _sachsen} =
  Locations.create_location(%{
    name: "Sachsen",
    code: "SN",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _sachsenanhalt} =
  Locations.create_location(%{
    name: "Sachsen-Anhalt",
    code: "ST",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _schleswigholstein} =
  Locations.create_location(%{
    name: "Schleswig-Holstein",
    code: "SH",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, _thueringen} =
  Locations.create_location(%{
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

# Seed holiday or vacation types
#
{:ok, _herbst} =
  Calendars.create_holiday_or_vacation_type(%{
    name: "Herbst",
    colloquial: "Herbstferien",
    default_html_class: "success",
    default_is_listed_below_month: true,
    default_is_school_vacation: true,
    default_is_valid_for_students: true,
    # default_display_priority: 4,
    wikipedia_url: "https://de.m.wikipedia.org/wiki/Schulferien#Herbstferien",
    country_location_id: deutschland.id,
    default_display_priority: 5
  })

{:ok, _weihnachten} =
  Calendars.create_holiday_or_vacation_type(%{
    name: "Weihnachten",
    colloquial: "Weihnachtsferien",
    default_html_class: "success",
    default_is_listed_below_month: true,
    default_is_school_vacation: true,
    default_is_valid_for_students: true,
    # default_display_priority: 4,
    wikipedia_url: "https://de.m.wikipedia.org/wiki/Schulferien#Weihnachtsferien",
    country_location_id: deutschland.id,
    default_display_priority: 5
  })

{:ok, _winter} =
  Calendars.create_holiday_or_vacation_type(%{
    name: "Winter",
    colloquial: "Winterferien",
    default_html_class: "success",
    default_is_listed_below_month: true,
    default_is_school_vacation: true,
    default_is_valid_for_students: true,
    # default_display_priority: 4,
    wikipedia_url:
      "https://de.m.wikipedia.org/wiki/Schulferien#Winter-/Sport-/Zeugnis-/Semester-/Faschingsferien",
    country_location_id: deutschland.id,
    default_display_priority: 5
  })

{:ok, _ostern} =
  Calendars.create_holiday_or_vacation_type(%{
    name: "Ostern/Frühjahr",
    colloquial: "Osterferien",
    default_html_class: "success",
    default_is_listed_below_month: true,
    default_is_school_vacation: true,
    default_is_valid_for_students: true,
    # default_display_priority: 4,
    wikipedia_url:
      "https://de.m.wikipedia.org/wiki/Schulferien#Oster-/Frühjahrs-/Frühlingsferien",
    country_location_id: deutschland.id,
    default_display_priority: 5
  })

{:ok, _pfingsten} =
  Calendars.create_holiday_or_vacation_type(%{
    name: "Himmelfahrt/Pfingsten",
    colloquial: "Pfingstferien",
    default_html_class: "success",
    default_is_listed_below_month: true,
    default_is_school_vacation: true,
    default_is_valid_for_students: true,
    # default_display_priority: 4,
    wikipedia_url: "https://de.m.wikipedia.org/wiki/Schulferien#Pfingstferien",
    country_location_id: deutschland.id,
    default_display_priority: 5
  })

{:ok, _sommer} =
  Calendars.create_holiday_or_vacation_type(%{
    name: "Sommer",
    colloquial: "Sommerferien",
    default_html_class: "success",
    default_is_listed_below_month: true,
    default_is_school_vacation: true,
    default_is_valid_for_students: true,
    # default_display_priority: 4,
    wikipedia_url: "https://de.m.wikipedia.org/wiki/Schulferien#Sommerferien",
    country_location_id: deutschland.id,
    default_display_priority: 5
  })

{:ok, _beweglicher_ferientag} =
  Calendars.create_holiday_or_vacation_type(%{
    name: "Beweglicher Ferientag",
    default_html_class: "success",
    default_is_listed_below_month: true,
    default_is_school_vacation: true,
    default_is_valid_for_students: true,
    # default_display_priority: 3,
    wikipedia_url: "https://de.wikipedia.org/wiki/Bewegliche_Ferientage",
    country_location_id: deutschland.id,
    default_display_priority: 7
  })

{:ok, _wochenende} =
  Calendars.create_holiday_or_vacation_type(%{
    name: "Wochenende",
    default_html_class: "active",
    default_is_listed_below_month: false,
    default_is_school_vacation: false,
    default_is_valid_for_everybody: true,
    # default_display_priority: 2,
    wikipedia_url: "https://de.m.wikipedia.org/wiki/Schulferien#Sommerferien",
    country_location_id: deutschland.id,
    default_display_priority: 4
  })

{:ok, _corona_quarantine} =
  Calendars.create_holiday_or_vacation_type(%{
    name: "Corona Virus Quarantäne",
    default_html_class: "warning",
    default_is_listed_below_month: true,
    default_is_school_vacation: true,
    default_is_valid_for_everybody: false,
    default_is_valid_for_students: true,
    wikipedia_url: "https://de.wikipedia.org/wiki/COVID-19-Pandemie",
    country_location_id: deutschland.id,
    default_display_priority: 9
  })
