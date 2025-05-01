# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :mehr_schulferien,
  ecto_repos: [MehrSchulferien.Repo]

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

# Configure websocket adapter
config :phoenix, :socket_handlers, [Phoenix.Transports.WebSocket]

# Configure esbuild
config :esbuild,
  version: "0.17.11"

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
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
