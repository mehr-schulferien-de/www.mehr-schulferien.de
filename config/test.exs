use Mix.Config

# Configure your database
if System.get_env("GITHUB_ACTIONS") do
  # Configure the database for GitHub Actions
  config :mehr_schulferien, MehrSchulferien.Repo,
    username: "postgres",
    password: "postgres",
    database: "mehr_schulferien_test",
    hostname: "localhost",
    pool: Ecto.Adapters.SQL.Sandbox
else
  config :mehr_schulferien, MehrSchulferien.Repo,
    username: "postgres",
    password: "postgres",
    database: "mehr_schulferien_test",
    hostname: "localhost",
    pool: Ecto.Adapters.SQL.Sandbox
end

# Mailer test configuration
config :mehr_schulferien, MehrSchulferienWeb.Mailer, adapter: Bamboo.TestAdapter

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mehr_schulferien, MehrSchulferienWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
