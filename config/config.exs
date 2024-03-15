# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :mehr_schulferien,
  ecto_repos: [MehrSchulferien.Repo]

# Configures the endpoint
config :mehr_schulferien, MehrSchulferienWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "wt0jWSOR3yQpDxdWDMOdkjAMgWc99flPw5EfR3fnYm4zouQKoPNqCi40BE3maX8/",
  render_errors: [view: MehrSchulferienWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: MehrSchulferien.PubSub

# Mailer configuration
config :mehr_schulferien, MehrSchulferienWeb.Mailer, adapter: Bamboo.LocalAdapter

# Phauxth authentication configuration
config :phauxth,
  user_context: MehrSchulferien.Accounts,
  crypto_module: Argon2,
  token_module: MehrSchulferienWeb.Auth.Token,
  user_messages: MehrSchulferienWeb.Auth.UserMessages

# Mailer configuration
config :mehr_schulferien, MehrSchulferienWeb.Mailer, adapter: Bamboo.LocalAdapter

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
