# mehr-schulferien.de

This project is the 2020 (last update 2024) version of 
https://www.mehr-schulferien.de

The webpage provides information about school vacations and public holidays
in Germany.

# Developers

See the [contributing guide](https://github.com/mehr-schulferien-de/www.mehr-schulferien.de/blob/master/CONTRIBUTING.md)
for more information about setting up your development environment and opening pull
requests.

## Data structure

The situation: We have countries, federal_states, counties, cities and schools.
They all have different possibilities to set vacation dates or public holidays.

We aim to be able to render all pages on the fly. So our main problem is to make it possible that we can read the needed data fast. That is the idea behind the data model.

### Maps

Locations are the table which stores countries, federal_states, counties, cities and schools. They are all linked to the parent_location. By that, we can walk up
the tree.

A city can have multiple zip_codes and one zip_code can belong to multiple cities.
Therefore we have a zip_code_mapping table which connects them to the location
of a city.

## Calendars

Religion stores available religions. holiday_or_vacation_types stores the
types of different holidays and vacations. periods store the actual dates.

# Development System

To start your Phoenix server:

  * Clone the project
  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `priv/repo/reset-db.sh`
  * Start Phoenix endpoint with `iex -S mix phx.server`

Open [`localhost:4000`](http://localhost:4000) in your browser.

Open an issue in case you run into any problems.
