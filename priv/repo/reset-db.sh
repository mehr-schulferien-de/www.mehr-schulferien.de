#!/bin/bash
set -e

mix ecto.reset
mix run priv/repo/seed_cities.exs
mix run priv/repo/seeds-public-holidays.exs
mix run priv/repo/seeds-vacations.exs
mix run priv/repo/seeds-schools.exs
