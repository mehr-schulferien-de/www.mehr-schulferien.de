# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

import Config

# Configure your database
config :mehr_schulferien, MehrSchulferien.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "mehr_schulferien_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mehr_schulferien, MehrSchulferienWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Hs+Hs+Hs+Hs+Hs+Hs+Hs+Hs+Hs+Hs+Hs+Hs+Hs+Hs+Hs+Hs+Hs+Hs+Hs+Hs+Hs+Hs+",
  server: true

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
