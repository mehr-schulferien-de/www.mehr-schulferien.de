# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

import Config

# Set environment
config :mehr_schulferien, :env, :test

# The wiki night curfew (22:00-06:00 Berlin time) reads the real clock;
# without this override the whole wiki suite would fail every evening.
config :mehr_schulferien, wiki_hours_override: :open

# Enable school contact info for tests (disabled in production for legal reasons)
config :mehr_schulferien, school_contact_info_enabled: true

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

# Print only errors during test (suppress warnings)
config :logger, level: :error

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Configure Swoosh for test
config :mehr_schulferien, MehrSchulferien.Mailer, adapter: Swoosh.Adapters.Test

# Disable Swoosh mailbox in test
config :swoosh, :serve_mailbox, false

# The ad-stats Recorder is not auto-started in test: the SQL sandbox owns
# the database, so tests that measure start their own supervised instance.
config :mehr_schulferien, start_ad_recorder: false

# Calendar PDFs: no pdflatex in the suite (tests tagged :pdflatex bring their
# own compiler), a store outside the source tree, and no background warmer.
config :mehr_schulferien,
  calendar_pdf_compiler: MehrSchulferien.CalendarPdfStubCompiler,
  calendar_pdf_dir:
    Path.join(
      System.tmp_dir!(),
      "mehr_schulferien_test_calendar_pdfs#{System.get_env("MIX_TEST_PARTITION")}"
    ),
  start_calendar_pdf_warmer: false
