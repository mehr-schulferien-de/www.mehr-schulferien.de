defmodule MehrSchulferienWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :mehr_schulferien

  socket "/socket", MehrSchulferienWeb.UserSocket,
    websocket: true,
    longpoll: false,
    drainer: [
      batch_size: 10000,
      batch_interval: 2000,
      shutdown: 30000
    ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: true,
    longpoll: false,
    drainer: [
      batch_size: 10000,
      batch_interval: 2000,
      shutdown: 30000
    ]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :mehr_schulferien,
    gzip: false,
    only: ~w(assets css fonts images favicon.ico robots.txt ads.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_mehr_schulferien_key",
    signing_salt: "ld6G7jfc"

  if Application.compile_env(:mehr_schulferien, :env) == :dev do
    plug Tidewave
  end

  plug MehrSchulferienWeb.Router
end
