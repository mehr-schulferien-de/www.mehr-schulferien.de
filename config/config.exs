# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configure timezone database to use tzdata
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :mehr_schulferien,
  ecto_repos: [MehrSchulferien.Repo],
  # Configure pdflatex path (can be overridden in environment configs)
  pdflatex_path: "pdflatex",
  # Email configuration
  admin_email: "sw@wintermeyer-consulting.de",
  admin_name: "Stefan Wintermeyer",
  support_email: "support@mehr-schulferien.de",
  noreply_email: "noreply@mehr-schulferien.de",
  system_email_name: "MehrSchulferien System"

# Configures the endpoint
config :mehr_schulferien, MehrSchulferienWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "your-secret-key-base-here",
  render_errors: [view: MehrSchulferienWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: MehrSchulferien.PubSub,
  live_view: [signing_salt: "your-signing-salt-here"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure paper_trail
config :paper_trail, repo: MehrSchulferien.Repo

# Configure websocket adapter
config :phoenix, :socket_handlers, [Phoenix.Transports.WebSocket]

# Configure esbuild
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* --external:*.css),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure Tailwind
config :tailwind,
  version: "3.4.6",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ],
  # Production build with minification
  production: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
      --minify
    ),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_ENV" => "production"}
  ]

# Configure Swoosh API client
config :swoosh, :api_client, Swoosh.ApiClient.Hackney

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
