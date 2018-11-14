# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# TODO: Add cities, schools
germany = Country.create(name: 'Deutschland', code: 'DE')

FederalState.create(
  [
    { name: 'Baden-Württemberg', code: 'BW', country: germany },
    { name: 'Bayern', code: 'BY', country: germany },
    { name: 'Berlin', code: 'BE', country: germany },
    { name: 'Brandenburg', code: 'BB', country: germany },
    { name: 'Bremen', code: 'HB', country: germany },
    { name: 'Hamburg', code: 'HH', country: germany },
    { name: 'Hessen', code: 'HE', country: germany },
    { name: 'Mecklenburg-Vorpommern', code: 'MV', country: germany },
    { name: 'Niedersachsen', code: 'NI', country: germany },
    { name: 'Nordrhein-Westfalen', code: 'NW', country: germany },
    { name: 'Rheinland-Pfalz', code: 'RP', country: germany },
    { name: 'Saarland', code: 'SL', country: germany },
    { name: 'Sachsen', code: 'SN', country: germany },
    { name: 'Sachen-Anhalt', code: 'ST', country: germany },
    { name: 'Schleswig-Holstein', code: 'SH', country: germany },
    { name: 'Thüringen', code: 'TH', country: germany }
  ]
)

Year.create(
  [
    { value: Date.today.year },
    { value: Date.today.year + 1 },
    { value: Date.today.year + 2 },
    { value: Date.today.year + 3 }
  ]
)

Category.create(
  [
    { value: 'Schulferien' },
    { value: 'Gesetzlicher Feiertag' },
    { value: 'Beweglicher Ferientag' },
    { value: 'Islamischer Feiertag' },
    { value: 'Jüdischer Feiertag' },
    { value: 'Griechisch-Orthodoxer Feiertag' },
    { value: 'Russisch-Orthodoxer Feiertag' }
  ]
)
