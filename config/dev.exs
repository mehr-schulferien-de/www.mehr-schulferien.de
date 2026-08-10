import Config

# Set environment
config :mehr_schulferien, :env, :dev

# Configure your database
config :mehr_schulferien, MehrSchulferien.Repo,
  username: "postgres",
  password: "postgres",
  database: "mehr_schulferien_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  # Optimized connection pool settings for better performance
  queue_target: 50,
  queue_interval: 1000,
  # Prepare statements for better query performance
  prepare: :named,
  # Connection timeout
  timeout: 15_000,
  # Pool timeout
  pool_timeout: 5_000

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application.
config :mehr_schulferien, MehrSchulferienWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "IsQ9eDEOmilKcgFSSbzHvIp8ZfX64ME52Dc3ipVM2yrH/ygy7sQe/NDS4jt3EW6N",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading.
config :mehr_schulferien, MehrSchulferienWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/mehr_schulferien_web/(live|views)/.*(ex)$",
      ~r"lib/mehr_schulferien_web/templates/.*(eex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Configure Swoosh for development
config :mehr_schulferien, MehrSchulferien.Mailer, adapter: Swoosh.Adapters.Local

# Disable Swoosh's own web server - we'll use Phoenix's router instead
config :swoosh, :serve_mailbox, false
