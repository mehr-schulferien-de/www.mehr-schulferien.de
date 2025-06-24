# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
use Mix.Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :mehr_schulferien, MehrSchulferien.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :mehr_schulferien, MehrSchulferienWeb.Endpoint,
  http: [:inet6, port: String.to_integer(System.get_env("PORT") || "4000")],
  secret_key_base: secret_key_base,
  debug_errors: true

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :mehr_schulferien, MehrSchulferienWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.

# Configure Swoosh for production
# You can switch adapters based on environment variables
mailer_adapter = System.get_env("MAILER_ADAPTER") || "smtp"

case mailer_adapter do
  "smtp" ->
    config :mehr_schulferien, MehrSchulferien.Mailer,
      adapter: Swoosh.Adapters.SMTP,
      relay: System.get_env("SMTP_RELAY") || "localhost",
      port: String.to_integer(System.get_env("SMTP_PORT") || "587"),
      username: System.get_env("SMTP_USERNAME"),
      password: System.get_env("SMTP_PASSWORD"),
      tls: if(System.get_env("SMTP_TLS") == "false", do: :never, else: :always),
      auth: :always

  "sendgrid" ->
    config :mehr_schulferien, MehrSchulferien.Mailer,
      adapter: Swoosh.Adapters.Sendgrid,
      api_key: System.get_env("SENDGRID_API_KEY") || raise("SENDGRID_API_KEY is required")

  "mailgun" ->
    config :mehr_schulferien, MehrSchulferien.Mailer,
      adapter: Swoosh.Adapters.Mailgun,
      api_key: System.get_env("MAILGUN_API_KEY") || raise("MAILGUN_API_KEY is required"),
      domain: System.get_env("MAILGUN_DOMAIN") || raise("MAILGUN_DOMAIN is required")

  "ses" ->
    config :mehr_schulferien, MehrSchulferien.Mailer,
      adapter: Swoosh.Adapters.AmazonSES,
      region: System.get_env("AWS_REGION") || "us-east-1",
      access_key: System.get_env("AWS_ACCESS_KEY") || raise("AWS_ACCESS_KEY is required"),
      secret: System.get_env("AWS_SECRET") || raise("AWS_SECRET is required")

  _ ->
    # Default to local adapter if nothing is configured
    config :mehr_schulferien, MehrSchulferien.Mailer, adapter: Swoosh.Adapters.Local
end
