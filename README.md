# MehrSchulferien

This project is the 2020 version of https://www.mehr-schulferien.de
It is a webpage which displays school vacation and public holidays in Germany.

## Data structure

The situation: We have countries, federal_states, counties, cities and schools. 
They all have different possiblities to set vacation dates or public holidays. 

We aim to be able to render all pages on the fly. So our main problem is to make 
it possible that we can read the needed data fast. That is the idea behind the 
data model. 

### Maps

Locations is the table which stores countries, federal_states, counties, cities 
and schools. They are all linked to the parent_location. By that we can walk up 
the tree.

A city can have multiple zip_codes and one zip_code can belong to multiple cities. 
Therefore we have a zip_code_mapping table which connects them to the location 
of a city.

## Calendars

Religion stores the available religions. holiday_or_vacation_types stores the 
types of different holidays and vacations. periods store the actual dates.

## More to come

This document will be updated regulary. 

## Seeds

The seedings process is not finalized yet. Until then you have to do the following steps:

- mix run priv/repo/seeds.exs
- mix run priv/repo/seeds-vacations.exs
- mix run priv/repo/seed_cities.exs

The list will get longer while other enties get ready for seeding. The README will be updated regulary.

# Phoenix

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
