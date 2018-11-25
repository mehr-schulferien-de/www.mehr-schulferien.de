# MehrSchulferien

## Software versions

- Elixir: 1.5.2
- Erlang: 20.3.8.9
- node: 8.8.1
- NPM: 5.4.2

## Postgres

createuser -s postgres

## Setup

To start your Phoenix server:

  * Delete an existing deps directory. `rm -rf deps`
  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Seed the database with `mix run priv/repo/seeds.exs`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

# Misc

The current set of Twitter Bootstrap CSS is available at
https://getbootstrap.com/docs/3.3/customize/?id=9efb65c1750c4e7446771f8df668ec33
