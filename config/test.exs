use Mix.Config

# Configure your database
config :mehr_schulferien, MehrSchulferien.Repo,
  username: "postgres",
  password: "postgres",
  database: "mehr_schulferien_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mehr_schulferien, MehrSchulferienWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
