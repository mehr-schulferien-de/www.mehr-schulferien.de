# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias MehrSchulferien.Locations
alias MehrSchulferien.Calendars

# Countries
#
{:ok, deutschland} =
  Locations.create_location(%{name: "Deutschland", code: "DE", is_country: true, slug: "d"})

# Create the federal_states of Deutschland
#
{:ok, badenwuerttemberg} =
  Locations.create_location(%{
    name: "Baden-Württemberg",
    code: "BW",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, bayern} =
  Locations.create_location(%{
    name: "Bayern",
    code: "BY",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, berlin} =
  Locations.create_location(%{
    name: "Berlin",
    code: "BE",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, brandenburg} =
  Locations.create_location(%{
    name: "Brandenburg",
    code: "BB",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, bremen} =
  Locations.create_location(%{
    name: "Bremen",
    code: "HB",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, hamburg} =
  Locations.create_location(%{
    name: "Hamburg",
    code: "HH",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, hessen} =
  Locations.create_location(%{
    name: "Hessen",
    code: "HE",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, mecklenburgvorpommern} =
  Locations.create_location(%{
    name: "Mecklenburg-Vorpommern",
    code: "MV",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, niedersachsen} =
  Locations.create_location(%{
    name: "Niedersachsen",
    code: "NI",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, nordrheinwestfalen} =
  Locations.create_location(%{
    name: "Nordrhein-Westfalen",
    code: "NW",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, rheinlandpfalz} =
  Locations.create_location(%{
    name: "Rheinland-Pfalz",
    code: "RP",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, saarland} =
  Locations.create_location(%{
    name: "Saarland",
    code: "SL",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, sachsen} =
  Locations.create_location(%{
    name: "Sachsen",
    code: "SN",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, sachsenanhalt} =
  Locations.create_location(%{
    name: "Sachsen-Anhalt",
    code: "ST",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, schleswigholstein} =
  Locations.create_location(%{
    name: "Schleswig-Holstein",
    code: "SH",
    is_federal_state: true,
    parent_location_id: deutschland.id
  })

{:ok, thueringen} =
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
  Calendars.create_religion(%{
    name: "Islam",
    wikipedia_url: "https://de.wikipedia.org/wiki/Islam"
  })

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
    wikipedia_url: "https://de.m.wikipedia.org/wiki/Schulferien#Sommerferien",
    country_location_id: deutschland.id,
    default_display_priority: 5
  })

{:ok, _beweglicher_ferientag} =
  Calendars.create_holiday_or_vacation_type(%{
    name: "Beweglicher Ferientag",
    colloquial: "Beweglicher Ferientag",
    default_html_class: "success",
    default_is_listed_below_month: true,
    default_is_school_vacation: true,
    default_is_valid_for_students: true,
    wikipedia_url: "https://de.wikipedia.org/wiki/Bewegliche_Ferientage",
    country_location_id: deutschland.id,
    default_display_priority: 7
  })

{:ok, _wochenende} =
  Calendars.create_holiday_or_vacation_type(%{
    name: "Wochenende",
    colloquial: "Wochenende",
    default_html_class: "active",
    default_is_listed_below_month: false,
    default_is_school_vacation: false,
    default_is_valid_for_everybody: true,
    wikipedia_url: "https://de.m.wikipedia.org/wiki/Schulferien#Sommerferien",
    country_location_id: deutschland.id,
    default_display_priority: 4
  })

{:ok, corona_quarantine} =
  Calendars.create_holiday_or_vacation_type(%{
    name: "Schulschließung wegen der COVID-19-Pandemie (Corona)",
    colloquial: "Corona-Schulschließung",
    default_html_class: "danger",
    default_is_listed_below_month: true,
    default_is_school_vacation: true,
    default_is_valid_for_everybody: false,
    default_is_valid_for_students: true,
    wikipedia_url: "https://de.wikipedia.org/wiki/COVID-19-Pandemie",
    country_location_id: deutschland.id,
    default_display_priority: 20
  })

# Corona quarantine dates
#

MehrSchulferien.Periods.create_period(%{
  created_by_email_address: "sw@wintermeyer-consulting.de",
  holiday_or_vacation_type_id: corona_quarantine.id,
  starts_on: "2020-03-16",
  ends_on: "2020-04-03",
  location_id: badenwuerttemberg.id,
  display_priority: 20
})

MehrSchulferien.Periods.create_period(%{
  created_by_email_address: "sw@wintermeyer-consulting.de",
  holiday_or_vacation_type_id: corona_quarantine.id,
  starts_on: "2020-03-16",
  ends_on: "2020-04-03",
  location_id: bayern.id,
  display_priority: 20
})

MehrSchulferien.Periods.create_period(%{
  created_by_email_address: "sw@wintermeyer-consulting.de",
  holiday_or_vacation_type_id: corona_quarantine.id,
  starts_on: "2020-03-16",
  ends_on: "2020-04-03",
  location_id: berlin.id,
  display_priority: 20
})

MehrSchulferien.Periods.create_period(%{
  created_by_email_address: "sw@wintermeyer-consulting.de",
  holiday_or_vacation_type_id: corona_quarantine.id,
  starts_on: "2020-03-16",
  ends_on: "2020-04-03",
  location_id: brandenburg.id,
  display_priority: 20
})

MehrSchulferien.Periods.create_period(%{
  created_by_email_address: "sw@wintermeyer-consulting.de",
  holiday_or_vacation_type_id: corona_quarantine.id,
  starts_on: "2020-03-16",
  ends_on: "2020-03-27",
  location_id: bremen.id,
  display_priority: 20
})

MehrSchulferien.Periods.create_period(%{
  created_by_email_address: "sw@wintermeyer-consulting.de",
  holiday_or_vacation_type_id: corona_quarantine.id,
  starts_on: "2020-03-16",
  ends_on: "2020-04-09",
  location_id: hamburg.id,
  display_priority: 20
})

MehrSchulferien.Periods.create_period(%{
  created_by_email_address: "sw@wintermeyer-consulting.de",
  holiday_or_vacation_type_id: corona_quarantine.id,
  starts_on: "2020-03-16",
  ends_on: "2020-04-03",
  location_id: hessen.id,
  display_priority: 20
})

MehrSchulferien.Periods.create_period(%{
  created_by_email_address: "sw@wintermeyer-consulting.de",
  holiday_or_vacation_type_id: corona_quarantine.id,
  starts_on: "2020-03-16",
  ends_on: "2020-04-03",
  location_id: mecklenburgvorpommern.id,
  display_priority: 20
})

MehrSchulferien.Periods.create_period(%{
  created_by_email_address: "sw@wintermeyer-consulting.de",
  holiday_or_vacation_type_id: corona_quarantine.id,
  starts_on: "2020-03-16",
  ends_on: "2020-03-27",
  location_id: niedersachsen.id,
  display_priority: 20
})

MehrSchulferien.Periods.create_period(%{
  created_by_email_address: "sw@wintermeyer-consulting.de",
  holiday_or_vacation_type_id: corona_quarantine.id,
  starts_on: "2020-03-16",
  ends_on: "2020-04-03",
  location_id: nordrheinwestfalen.id,
  display_priority: 20
})

MehrSchulferien.Periods.create_period(%{
  created_by_email_address: "sw@wintermeyer-consulting.de",
  holiday_or_vacation_type_id: corona_quarantine.id,
  starts_on: "2020-03-16",
  ends_on: "2020-04-08",
  location_id: rheinlandpfalz.id,
  display_priority: 20
})

MehrSchulferien.Periods.create_period(%{
  created_by_email_address: "sw@wintermeyer-consulting.de",
  holiday_or_vacation_type_id: corona_quarantine.id,
  starts_on: "2020-03-16",
  ends_on: "2020-04-09",
  location_id: saarland.id,
  display_priority: 20
})

MehrSchulferien.Periods.create_period(%{
  created_by_email_address: "sw@wintermeyer-consulting.de",
  holiday_or_vacation_type_id: corona_quarantine.id,
  starts_on: "2020-03-16",
  ends_on: "2020-04-09",
  location_id: sachsen.id,
  display_priority: 20
})

MehrSchulferien.Periods.create_period(%{
  created_by_email_address: "sw@wintermeyer-consulting.de",
  holiday_or_vacation_type_id: corona_quarantine.id,
  starts_on: "2020-03-16",
  ends_on: "2020-04-03",
  location_id: sachsenanhalt.id,
  display_priority: 20
})

MehrSchulferien.Periods.create_period(%{
  created_by_email_address: "sw@wintermeyer-consulting.de",
  holiday_or_vacation_type_id: corona_quarantine.id,
  starts_on: "2020-03-16",
  ends_on: "2020-03-27",
  location_id: schleswigholstein.id,
  display_priority: 20
})

MehrSchulferien.Periods.create_period(%{
  created_by_email_address: "sw@wintermeyer-consulting.de",
  holiday_or_vacation_type_id: corona_quarantine.id,
  starts_on: "2020-03-16",
  ends_on: "2020-04-03",
  location_id: thueringen.id,
  display_priority: 20
})
