# MehrSchulferien

This project is the 2020 version of https://www.mehr-schulferien.de
It is a webpage which displays school vacation and public holidays in Germany.

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
